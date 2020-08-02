FROM ubuntu:20.04

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV TERM screen

# So we can source (see http://goo.gl/oBPi5G)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Ubuntu software that are used by CoCalc (latex, pandoc, sage, jupyter)
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
     git wget dpkg-dev sshfs postgresql libpq5 libpq-dev sqlite3 libsqlite3-dev python3-yaml python jupyter python3-pip

RUN \
     wget -qO- https://deb.nodesource.com/setup_12.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs libxml2-dev libxslt-dev \
  && /usr/bin/npm install -g npm

RUN \
     cd / \
  && git clone https://github.com/sagemathinc/cocalc \
  && cd /cocalc/src \
  && npm run make


RUN \
     cd /cocalc/src/ \
  && pip3 install smc_pyutil/ \
  && pip3 install smc_sagews/

# Make sure it compiles (and also cache the compiled js).
RUN \
     cd /cocalc/src \
  && . ./smc-env \
  && cd smc-project \
  && coffee ./local_hub.coffee  --test

ENV COCALC_PROJECT_ID SET_ME
ENV COCALC_SERVER     YOU_MUST_SET_ME
ENV COCALC_SSH_PORT   22

# Copy over the run script that connects to the remote cocalc project
# forwards ports.

COPY run.sh /run.sh

CMD /run.sh