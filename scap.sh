#!/bin/bash

SCC_VERSION=5.8
STIG_VERSION=V1R13
BENCHMARK_VERSION=V1R12

curl -LO https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/scc-${SCC_VERSION}_rhel8_oracle-linux8_x86_64_bundle.zip
curl -LO https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_8_${BENCHMARK_VERSION}_STIG_SCAP_1-2_Benchmark.zip
unzip scc-${SCC_VERSION}_rhel8_oracle-linux8_x86_64_bundle.zip

dnf --nogpgcheck install scc-${SCC_VERSION}_rhel8_x86_64/scc-${SCC_VERSION}.rhel8.x86_64.rpm -y

/opt/scc/cscc --disableAll
/opt/scc/cscc --setProfile MAC-3_Sensitive
/opt/scc/cscc -isr --setOpt ignoreCPEOVALResults 1 --force ./U_RHEL_8_${BENCHMARK_VERSION}_STIG_SCAP_1-2_Benchmark.zip
