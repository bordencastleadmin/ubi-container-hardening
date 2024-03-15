#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y \
  && rm -rf ${BUILDER} && \ 
  chmod 0755 /usr/bin/launch && \
  chmod 0755 /usr/bin/logging.sh && \
  chmod 0755 /bin/launch && \
  chmod 0755 /bin/logging.sh
