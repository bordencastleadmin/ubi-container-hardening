#!/bin/bash
# Simple Multi-OS Compliance Hardening Script
# Uses ComplianceAsCode/content repository
# Supports RHEL/UBI 8, 9, and 10

set -e

# Default version if not provided
DEFAULT_COMPLIANCE_AS_CODE_VERSION="0.1.77"

# Parse command line arguments
usage() {
    echo "Usage: $0 [--version VERSION]"
    echo "  --version VERSION    Specify ComplianceAsCode version (default: $DEFAULT_COMPLIANCE_AS_CODE_VERSION)"
    echo "  -h, --help          Show this help message"
    exit 1
}

# Check if COMPLIANCE_AS_CODE_VERSION environment variable is set, otherwise use default
COMPLIANCE_AS_CODE_VERSION="${COMPLIANCE_AS_CODE_VERSION:-$DEFAULT_COMPLIANCE_AS_CODE_VERSION}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            COMPLIANCE_AS_CODE_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

echo "Using ComplianceAsCode version: $COMPLIANCE_AS_CODE_VERSION"

# Detect OS version
if [ -f /etc/redhat-release ]; then
    OS_TYPE="rhel"
    OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -n1)
    echo "Detected RHEL/UBI version: $OS_VERSION"
elif [ -f /etc/lsb-release ] || [ -f /etc/os-release ]; then
    OS_TYPE="ubuntu"
    if [ -f /etc/lsb-release ]; then
        OS_VERSION=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d'=' -f2)
    else
        OS_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
    echo "Detected Ubuntu version: $OS_VERSION"
else
    echo "Error: Could not detect supported OS (RHEL/UBI or Ubuntu)"
    exit 1
fi

# Install packages based on OS type and version
if [ "$OS_TYPE" = "rhel" ]; then
    # Check if dnf is available, if not, install it using microdnf
    if ! command -v dnf &> /dev/null; then
        if command -v microdnf &> /dev/null; then
            MICRODNF_DETECTED=true
            echo "microdnf detected, installing dnf"
            # Create cache directory and set permissions (ignore if already exists)
            mkdir -p /var/cache/yum/metadata || true
            chmod 755 /var/cache/yum/metadata 2>/dev/null || true
            # Clean and update microdnf cache first
            microdnf clean all
            microdnf update -y --refresh
            microdnf install -y dnf
            echo "dnf installed successfully"
        else
            echo "Error: dnf could not be found and microdnf is not available"
        fi
    fi

    # Install RHEL/UBI packages
    dnf update -y
    dnf install -y postfix unzip git crypto-policies-scripts
    PKG_MANAGER="dnf"
elif [ "$OS_TYPE" = "ubuntu" ]; then
    # Update package lists and install Ubuntu packages
    apt-get update -y
    # Pre-configure postfix for non-interactive installation
    echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections
    apt-get install -y postfix unzip git curl python3 python3-pip python3-venv python3-apt
    PKG_MANAGER="apt-get"
fi

# Configure OS-specific settings
if [ "$OS_TYPE" = "rhel" ]; then
    case $OS_VERSION in
        8)
            dnf install -y mailx python3.11-pip
            PYTHON_CMD="python3.11"
            PLAYBOOK_PATH="ansible/rhel8-playbook-stig.yml"
            ANSIBLE_VERSION="ansible==7.4.0"
            SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-08-040110,package_libreswan_installed"
            if [ "$MICRODNF_DETECTED" = true ]; then
                SKIP_TAGS="$SKIP_TAGS,CCE-80935-0,CCE-85897-7,CCE-85899-3"
            fi
            ;;
        9)
            dnf install -y s-nail python3-pip
            PYTHON_CMD="python3"
            PLAYBOOK_PATH="ansible/rhel9-playbook-stig.yml"
            ANSIBLE_VERSION="ansible==8.6.0"
            SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-09-040110,package_libreswan_installed"
            if [ "$MICRODNF_DETECTED" = true ]; then
                SKIP_TAGS="$SKIP_TAGS,CCE-80935-0,CCE-85897-7,CCE-85899-3"
            fi
            ;;
        10)
            dnf install -y python3-pip
            PYTHON_CMD="python3"
            PLAYBOOK_PATH="ansible/rhel10-playbook-stig.yml"
            ANSIBLE_VERSION="ansible==8.6.0"
            SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-10-040110,package_libreswan_installed,configure_crypto_policy"
            if [ "$MICRODNF_DETECTED" = true ]; then
                SKIP_TAGS="$SKIP_TAGS,CCE-80935-0,CCE-85897-7,CCE-85899-3"
            fi
            ;;
        *)
            echo "Error: Unsupported RHEL/UBI version: $OS_VERSION"
            echo "Supported RHEL/UBI versions: 8, 9, 10"
            exit 1
            ;;
    esac
elif [ "$OS_TYPE" = "ubuntu" ]; then
    case $OS_VERSION in
        22.04)
            PYTHON_CMD="python3"
            PLAYBOOK_PATH="ansible/ubuntu2204-playbook-stig.yml"
            ANSIBLE_VERSION="ansible==8.6.0"
            SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,DISA-STIG-UBTU-24-200610"
            ;;
        24.04)
            PYTHON_CMD="python3"
            PLAYBOOK_PATH="ansible/ubuntu2404-playbook-stig.yml"
            ANSIBLE_VERSION="ansible==8.6.0"
            SKIP_TAGS="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,DISA-STIG-UBTU-24-200610"
            ;;
        *)
            echo "Error: Unsupported Ubuntu version: $OS_VERSION"
            echo "Supported Ubuntu versions: 22.04, 24.04"
            exit 1
            ;;
    esac
fi

# Create virtual environment and run hardening
$PYTHON_CMD -m venv ansibletemp --system-site-packages
source ansibletemp/bin/activate \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install ${ANSIBLE_VERSION} \
    && echo "Fetching SCAP Security Guide release v${COMPLIANCE_AS_CODE_VERSION}..." \
    && RELEASE_TAG="v${COMPLIANCE_AS_CODE_VERSION}" \
    && ASSET_URL="https://github.com/ComplianceAsCode/content/releases/download/$RELEASE_TAG/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}.zip" \
    && curl -L -o content.zip "$ASSET_URL" \
    && unzip -q content.zip -d temp_content \
    && mv temp_content/scap-security-guide-*/ content \
    && rm -rf temp_content content.zip \
    && echo "=== Full directory listing under 'content/' ===" \
    && ls -R content \
    && ansible-playbook -i "localhost," -c local "content/$PLAYBOOK_PATH" --skip-tags="$SKIP_TAGS"

# Set FIPS crypto policy (RHEL only)
if [ "$OS_TYPE" = "rhel" ]; then
    update-crypto-policies --set FIPS
    echo "Hardening completed successfully for RHEL/UBI $OS_VERSION using ComplianceAsCode v${COMPLIANCE_AS_CODE_VERSION}"
elif [ "$OS_TYPE" = "ubuntu" ]; then
    echo "Hardening completed successfully for Ubuntu $OS_VERSION using ComplianceAsCode v${COMPLIANCE_AS_CODE_VERSION}"
    echo "Note: FIPS crypto policy configuration not applicable for Ubuntu"
fi
