# Reverse Port Forward Gateway

The goal of this document is by hand create a small proof of concept by hand manual reverse port forward via a manual ssh gateway using Docker on my laptop.  I'm using docker on my MacOS laptop using Docker desktop.   The following all worked for me.

## setup 2 docker containers s1 and s2 that both are running ssh servers and can be ssh'd to from the host machine and each other

Each container should be running Ubuntu linux and we'll be using a root account.

Here's how to do this:

```sh
docker run -d --name s1 -p 2222:22 --rm --privileged --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE --cap-add=NET_RAW -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro ubuntu tail -f /dev/null
docker run -d --name s2 -p 2223:22 --rm --privileged --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_BIND_SERVICE --cap-add=NET_RAW -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro ubuntu tail -f /dev/null

# Inside the containers, install and start the SSH service
docker exec -it s1 bash -c "apt-get update && apt-get install -y openssh-server && service ssh start"
docker exec -it s2 bash -c "apt-get update && apt-get install -y openssh-server && service ssh start"
```

## ssh from the host into s1

Here's how to do this:

```sh
# get my ssh key onto s1
docker exec -i s1 bash -c "mkdir -p /root/.ssh && cat > /root/.ssh/authorized_keys" < ~/.ssh/id_ed25519.pub

ssh -A root@localhost -p 2222
```

## Determine the ip addresses of s1 and s2 on the default network

This works fine.  

```sh
 docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' s1
 
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' s2
```

For me they are 172.17.0.2 and 172.17.0.3.

You can also install ifconfig via `apt install net-tools` and use ifconfig eth0:

```sh
docker exec -it s1 bash -c "ifconfig eth0 | grep inet" | cut -d: -f2 | awk '{print $2}'

docker exec -it s2 bash -c "ifconfig eth0 | grep inet" | cut -d: -f2 | awk '{print $2}'
```

## Use command= in an authorized keys file to make it so ssh into s1 is forwarded to s2

I.e., we want to setup s1 to be an ssh gateway, so when we ssh to root@s1 we end up on s2.

Here's how to do this:

```sh
# On s1, generate a new key pair for root
docker exec -it s1 bash -c "ssh-keygen -f /root/.ssh/id_rsa -N ''"

# Copy the public key of s1 to authorized_keys of s2
docker exec -i s1 bash -c "cat /root/.ssh/id_rsa.pub" | docker exec -i s2 bash -c "mkdir -p /root/.ssh && cat > /root/.ssh/authorized_keys" 

# Now this works:

wstein@max ~ % docker exec -it s1 bash      
root@d082cc72642a:/# ssh 172.17.0.3 


# On s1 authorized_keys, set the command for ssh forwarding
wstein@max ~ % ssh root@localhost -p 2222
root@d082cc72642a:~# apt install neovim

# put command="ssh 172.17.0.3" at begining of /root/.ssh/authorized_keys line

```

Now when I ssh into s1 I'm on s2 \-\- this is a normal ssh gateway:

```sh
wstein@max ~ % ssh root@localhost -p 2222
Welcome to Ubuntu 22.04.1 LTS (GNU/Linux 5.15.49-linuxkit aarch64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Sat Apr 29 00:51:57 2023 from 172.17.0.2
root@7105bdb3c36b:~# 
```

## Write a little http server running on the host on port 2000

Using nodejs write an extremely simple http server on port 2000 so that hitting http://localhost:2000 returns "Hello world".

Here's how to do this:

```sh
cd /tmp

echo "const http = require('http');
const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'text/plain');
  res.writeHead(200);
  res.end('Hello world');
});
server.listen(2000, () => console.log('HTTP server on port 2000')); " > server.js

# Then start the server using Node.js
node server.js

# confirm it works in another terminal:

wstein@max /tmp % curl localhost:2000
Hello world%
```

## Explicitly reverse port to make port 2000 on the host visible on s1 as port 2000 via reverse port forwarding.

Our ultimate goal is to make it so that when we ssh somehow to s1, then port 2000 on our host becomes visible as port 2000 on s1 via a reverse port forward gateway.

```sh
ssh -R 2000:localhost:2000 root@localhost -p 2222
```

This does successfully work and setup a port forward so that port 2000 on s1 is port 2000 on my laptop host.  And the gateway authorized\_keys file makes it so upon doing the above I have a shell on s2. But s2 of course doesn't have localhost:2000 yet.

## do it via command= and an ssh to s1

Here's how to do this. Modify on s1 /root/

```sh
root@d082cc72642a:~# cat .ssh/authorized_keys 
command="ssh 172.17.0.3 -R 2000:localhost:2000" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGIyIhguFWFIGSwRjsMlMoX3h5NAI2WImLEm7uDeXG5F wstein@Williams-MacBook-Pro-2.local

# Now, when you ssh from the host into s1, the port 2000 will be forwarded to s2
wstein@max ~ % ssh -R 2000:localhost:2000 root@localhost -p 2222
root@7105bdb3c36b:~# curl localhost:2000
Hello worldroot@7105bdb3c36b:~# 
root@7105bdb3c36b:~# # this is on s2!
root@7105bdb3c36b:~# 

wstein@max ~ % docker exec -i s2 bash -c "curl -s localhost:2000"
Hello world% 
```

## Conclusion

Oh, this is exactly like our current ssh gateway, except to make port forwarding stuff work, we have to change command command= line and add that forwarding in.  Of course when there are a bunch of different projects all wanting to reverse forward say port 6000, we have some book keeping to track, since all the ports have to be different on the gateway.

