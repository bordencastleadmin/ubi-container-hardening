#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y && \
  rm -rf ${BUILDER} && \
  chown -R root:root /lib/.build-id && \
  chown -R root:root /usr/lib/.build-id
