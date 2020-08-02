Run Docker image like this. You **MUST** specify three env variables:

- COCALC_PROJECT_ID - the project id of your project
- COCALC_SERVER - hostname or ip address of your cocalc-docker instance.
- COCALC_SSH_PORT - ssh port number on your cocalc docker server

For example, if you ran cocalc-docker as follows on a machine called kucalc.sagemath.org:

```
sudo docker run --name=cocalc-hub -d -v ~/cocalc-cluster/projects/hub:/projects -p 4043:443 -p 4022:22  sagemathinc/cocalc
```

and your `project_id` 79d3f1a0-918e-4ada-8b31-8d1114fcde40 then you start cocalc-remote like this:

```
docker run -it -e COCALC_PROJECT_ID=79d3f1a0-918e-4ada-8b31-8d1114fcde40 -e COCALC_SERVER=kucalc.sagemath.org -e COCALC_SSH_PORT=4022 --cap-add SYS_ADMIN --device /dev/fuse  --security-opt apparmor:unconfined  sagemathinc/cocalc-compute:latest
```
