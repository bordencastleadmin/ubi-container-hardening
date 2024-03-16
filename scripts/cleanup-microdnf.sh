#!/bin/bash
dnf remove python3.11-pip git scc* unzip -y && \
  rm -vf /etc/dnf/protected.d/dnf.conf && \
  rpm --nodeps -e dnf  && \
  microdnf clean all -y && \
  rm -rf ${BUILDER} && \
  chmod 0755 /usr/bin/launch && \
  chmod 0755 /usr/bin/launch/logging.sh && \
  chmod 0755 /bin/launch && \
  chmod 0755 /bin/launch/logging.sh && \
  chown -h -R root:root /lib/.build-id && \
  chown -h -R root:root /usr/lib/.build-id
