#!/bin/bash

# Simple Multi-OS Compliance Hardening Script
# Uses ComplianceAsCode/content repository
# Supports RHEL/UBI 8, 9, and 10

set -e

# Detect OS version
if [ -f /etc/redhat-release ]; then
    OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -n1)
    echo "Detected RHEL/UBI version: $OS_VERSION"
else
    echo "Error: Could not detect Red Hat based OS"
    exit 1
fi

# Install packages based on OS version
dnf update -y
dnf install -y postfix unzip git curl

case $OS_VERSION in
    8)
        dnf install -y mailx python3.11-pip
        PYTHON_CMD="python3.11"
        PLAYBOOK_PATH="ansible/rhel8-playbook-stig.yml"
        SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-08-040110"
        ;;
    9)
        dnf install -y s-nail python3-pip
        PYTHON_CMD="python3"
        PLAYBOOK_PATH="ansible/rhel9-playbook-stig.yml"
        SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-09-040110"
        ;;
    10)
        dnf install -y s-nail python3-pip
        PYTHON_CMD="python3"
        PLAYBOOK_PATH="ansible/rhel10-playbook-stig.yml"
        SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-10-040110"
        ;;
    *)
        echo "Error: Unsupported OS version: $OS_VERSION"
        echo "Supported versions: RHEL/UBI 8, 9, 10"
        exit 1
        ;;
esac

# Install pip and ansible
pip3 install --upgrade pip
pip3 install ansible ansible-core

# Create virtual environment and run hardening
$PYTHON_CMD -m venv ansibletemp
source ansibletemp/bin/activate \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install ansible ansible-core \
    && echo "Fetching latest release info..." \
    && RELEASE_INFO=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest) \
    && RELEASE_TAG=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/') \
    && RELEASE_URL=$(echo "$RELEASE_INFO" | grep '"zipball_url":' | sed -E 's/.*"zipball_url": "([^"]+)".*/\1/') \
    && echo "Downloading release: $RELEASE_TAG" \
    && curl -L -o content.zip "$RELEASE_URL" \
    && unzip -q content.zip -d temp_content \
    && mv temp_content/* content \
    && rm -rf temp_content \
    && rm content.zip \
    && ansible-playbook -i "localhost," -c local "content/$PLAYBOOK_PATH" --skip-tags="$SKIP_TAGS"

# Set FIPS crypto policy
update-crypto-policies --set FIPS

echo "Hardening completed successfully for RHEL/UBI $OS_VERSION"
