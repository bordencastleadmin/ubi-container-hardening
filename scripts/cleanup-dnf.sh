#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y && \
  rm -rf ${BUILDER} && \
  chown -h -R root:root /lib/.build-id && \
  chown -h -R root:root /usr/lib/.build-id
