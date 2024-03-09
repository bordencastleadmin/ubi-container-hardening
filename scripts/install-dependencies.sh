#!/bin/bash
dnf install mailx unzip python3.11-pip git -y 
pip3 install --upgrade pip 
pip3 install ansible ansible-core

cat <<EOF >> harden-ubi8.yml
---
- hosts: all
  roles:
     - ansible-role-rhel8-stig
EOF

python3.11 -m venv ansibletemp
source ansibletemp/bin/activate \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install ansible ansible-core \
    && git clone https://github.com/RedHatOfficial/ansible-role-rhel8-stig.git \
    && ansible-playbook -i "localhost," -c local harden-ubi8.yml --skip-tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-08-040110"

update-crypto-policies --set FIPS