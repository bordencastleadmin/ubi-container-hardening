#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y && \
  rm -rf ${BUILDER} && \ 
  chmod 0755 /usr/bin/launch && \
  chmod 0755 /usr/bin/launch/logging.sh && \
  chmod 0755 /bin/launch && \
  chmod 0755 /bin/launch/logging.sh && \
  chown -R root:root /lib/.build-id && \
  chown -R root:root /usr/lib/.build-id
