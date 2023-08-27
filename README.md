**DEPRECATED** -- this will no longer work at all.  It is replaced by https://github.com/sagemathinc/cocalc/tree/master/src/packages/compute

# CoCalc-BYOC -- Bring Your Own Compute to CoCalc -- use any alternative compute backend for a CoCalc project

**The Problem:** You have access for a few hours to a massive server somewhere behind a firewall with a GPU and tons of RAM, and you want to use its compute resources with all the juicy collaboration, TimeTravel, and other slick features of https://CoCalc.com. You definitely don't want to run CoCalc-docker directly on that random ephemeral server, then lose your data and history when the server is gone. CoCalc-Compute solves your problem.

**What it does:** CoCalc-Compute makes it possible to very easily use a CoCalc project, but with everything running as root with the compute environment on any computer you have access to. You can install anything, and only your files and collaboration use CoCalc itself.

**Why?** A million people have been asking me for this forever. I finally figured out how to do it!

**LIMITATIONS:** 
 - CoCalc-Compute only support [cocalc-docker](https://github.com/sagemathinc/cocalc-docker) servers right now. You can't use this with https://cocalc.com. Why? Because the ssh gateway there is tricky to deal with and other issues... Nothing impossible and coming soon if there is interest.
 - This is awkward-to-use **alpha** quality software, that will likely only be made more robust and easy to use, if significantly many people express interest.

## Quickstart

Here is how to use CoCalcCompute:

1. Run [cocalc-docker](https://github.com/sagemathinc/cocalc-docker) somewhere and be sure to expose the ssh server:

```
sudo docker run --name=cocalc-hub -d \
      -v ~/cocalc-cluster/projects/hub:/projects \
      -p 4043:443 -p 4022:22  sagemathinc/cocalc
```

2. Create a project in that cocalc-docker server you started (see the docs).

3. On a server that can ssh to your cocalc-docker server, run the cocalc-compute Docker container, but with the project_id, server, and port set below:

```
docker run -it \
   -e COCALC_PROJECT_ID=[SET ME TO A PROJECT UUID] \
   -e COCALC_SERVER=[SET ME TO A HOSTNAME OR IP ADDRESS] \
   -e COCALC_SSH_PORT=[OPTIONALLY SET ME TO A PORT]  \
   --cap-add SYS_ADMIN --device /dev/fuse  \
   --security-opt apparmor:unconfined \
   sagemathinc/cocalc-compute:latest
```

Here:

- COCALC_PROJECT_ID - the project id of your project
- COCALC_SERVER - hostname or ip address of your cocalc-docker instance.
- COCALC_SSH_PORT - ssh port number on your cocalc docker server (this would be 4022 in our example above.)

For example, you might use:

```
docker run -it \
   -e COCALC_PROJECT_ID=79d3f1a0-918e-4ada-8b31-8d1114fcde40 \
   -e COCALC_SERVER=kucalc.sagemath.org \
   -e COCALC_SSH_PORT=4022 \
   --cap-add SYS_ADMIN --device /dev/fuse  --security-opt apparmor:unconfined \
   sagemathinc/cocalc-compute:latest
```

4. After running the cocalc-compute, you'll be asked to enter a public key into your project by pasting a line of code into a terminal. Once you do that, press any key and within a few seconds then return to your project in cocalc and find that it is running inside that cocalc-compute container!

5. In particular, you'll see that almost no software is installed, but your project runs as the root user in that container. The files are still the same though (they are stored on cocalc-docker as usual), and all realtime sync editing and TimeTravel are also stored on cocalc-docker. In particular, you can collaborate with any other users of cocalc-docker.

6. When you hit control+c in your cocalc-compute container it will terminate and your project will automatically switch back to running on cocalc-docker as before, and no data should be lost.
