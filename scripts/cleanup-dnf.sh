#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y && \
  rm -rf ${BUILDER} && \
  chown -L -R root:root /lib/.build-id && \
  chown -L -R root:root /usr/lib/.build-id
