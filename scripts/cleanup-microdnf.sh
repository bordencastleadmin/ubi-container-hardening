#!/bin/bash
dnf remove python3.11-pip git scc* unzip -y && \
  rm -vf /etc/dnf/protected.d/dnf.conf && \
  rpm --nodeps -e dnf  && \
  microdnf clean all -y && \
  rm -rf ${BUILDER} && \
  [ -f /usr/bin/launch ] && chmod 0755 /usr/bin/launch || true && \
  [ -f /usr/bin/launch/logging.sh ] && chmod 0755 /usr/bin/launch/logging.sh || true && \
  [ -f /bin/launch ] && chmod 0755 /bin/launch || true && \
  [ -f /bin/launch/logging.sh ] && chmod 0755 /bin/launch/logging.sh || true && \
  [ -d /lib/.build-id ] && chown -R root:root /lib/.build-id || true && \
  [ -d /usr/lib/.build-id ] && chown -R root:root /usr/lib/.build-id || true
