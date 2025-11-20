#!/bin/bash
apt-get remove --purge -y git unzip python3-pip && \
  apt-get autoremove -y && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf ${BUILDER}