#!/bin/bash
python3 -m pip uninstall ansible ansible-core && \
  dnf remove git scc* python3.11-pip unzip -y && \
  rm -rf ${BUILDER} && \
  chown -R root:root /lib/.build-id && \
  chown -R root:root /usr/lib/.build-id
