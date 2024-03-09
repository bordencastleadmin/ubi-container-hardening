#!/bin/bash
dnf remove python3.11-pip git scc* unzip -y \
  && rm -vf /etc/dnf/protected.d/dnf.conf \
  && rpm --nodeps -e dnf \
  && microdnf clean all -y \
  && rm -rf ${BUILDER} 
