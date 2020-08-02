\#!/usr/bin/env bash
set -e

#########################################################################
# This file is part of CoCalc: Copyright © 2020 Sagemath, Inc.
# License: AGPLv3 s.t. "Commons Clause" – see LICENSE.md for details
# Please contact help@cocalc.com for a commercial-use license.
#########################################################################

# Generate the root user's ssh key pair
ssh-keygen -t ed25519 -N '' -f $HOME/.ssh/id_ed25519

# Get rid of interactive host check message
echo "StrictHostKeyChecking no" >> $HOME/.ssh/config

# Pause and show ~/.ssh/id_ed25519.pub to the user and tell them to add it to
# the ~/.ssh/authorized_keys file of their project.
printf "\n\n *********************************** \n"
printf "* Add the following public ssh key to the file ~/.ssh/authorized_keys"
printf "* in your cocalc-docker project (which must be running): "
printf "\n\nmkdir -p ~/.ssh && echo '`cat /$HOME/.ssh/id_ed25519.pub`' >> ~/.ssh/authorized_keys\n\n\n"
read -rsp $'Press any key to continue...\n' -n1 key

# Create the sshfs mount:
mkdir -p /projects/$COCALC_PROJECT_ID
sshfs -p ${COCALC_SSH_PORT:-22} -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 ${COCALC_PROJECT_ID//-/}@$COCALC_SERVER: /projects/$COCALC_PROJECT_ID/

# Create .smc/remote:
rm -f /projects/$COCALC_PROJECT_ID/.smc/remote
echo `ssh ${COCALC_PROJECT_ID//-/}@$COCALC_SERVER -p ${COCALC_SSH_PORT:-22} smc-status` > /projects/$COCALC_PROJECT_ID/.smc/remote

# Start local hub
rm -rf /projects/$COCALC_PROJECT_ID/.smc-remote
mkdir -p /projects/$COCALC_PROJECT_ID/.smc-remote
ln -sf /projects/$COCALC_PROJECT_ID/.smc/secret_token /projects/$COCALC_PROJECT_ID/.smc-remote/secret_token
cd /cocalc/src && . ./smc-env
SMC=/projects/$COCALC_PROJECT_ID/.smc-remote SMC_LOCAL_HUB_HOME=/projects/$COCALC_PROJECT_ID COCALC_USERNAME=`whoami` SMC_PROXY_HOST=localhost ./smc-project/bin/smc-local-hub start

# Stop local-hub in the cocalc-docker project.
ssh ${COCALC_PROJECT_ID//-/}@$COCALC_SERVER -p ${COCALC_SSH_PORT:-22} smc-local-hub stop

# Wait until local hub here has started its servers
until [ -f /projects/$COCALC_PROJECT_ID/.smc-remote/local_hub/local_hub.port ]
do
     sleep 1
done

until [ -f /projects/$COCALC_PROJECT_ID/.smc-remote/local_hub/raw.port ]
do
     sleep 1
done

# Setup the reverse port forwards, periodically touching .smc/remote:
while :
do
    ssh -t -R `cat /projects/$COCALC_PROJECT_ID/.smc/local_hub/local_hub.port`:localhost:`cat /projects/$COCALC_PROJECT_ID/.smc-remote/local_hub/local_hub.port` \
        -R `cat /projects/$COCALC_PROJECT_ID/.smc/local_hub/raw.port`:localhost:`cat /projects/$COCALC_PROJECT_ID/.smc-remote/local_hub/raw.port`\
        ${COCALC_PROJECT_ID//-/}@$COCALC_SERVER -p ${COCALC_SSH_PORT:-22} /usr/bin/watch -n 15 "printf '** cocalc-compute connected.  Hold Control+C to terminate. **'; touch $HOME/.smc/remote"
    sleep 1
done

