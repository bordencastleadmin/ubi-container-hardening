#!/bin/bash
apt-get remove --purge -y git unzip python3-pip python3.9-pip python3.11-pip python3.12-pip python3.13-pip python3-apt software-properties-common && \
  apt-get autoremove -y && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf ${BUILDER}