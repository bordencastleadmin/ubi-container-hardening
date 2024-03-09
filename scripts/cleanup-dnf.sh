#!/bin/bash
dnf remove git scc* python3.11-pip unzip -y \
  && rm -rf ${BUILDER} 
