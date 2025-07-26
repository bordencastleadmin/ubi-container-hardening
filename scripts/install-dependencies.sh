# Function to create appropriate playbook
create_playbook() {
    local playbook_file="harden-ubi${OS_VERSION}.yml"
    local role_name=""
    local skip_tags=""
    
    case $OS_VERSION in
        8)
            role_name="ansible-role-rhel8-stig"
            skip_tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-08-040110"
            ;;
        9)
            role_name="ansible-role-rhel9-stig"
            skip_tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-09-040110"
            ;;
        10)
            echo "WARNING: RHEL 10 STIG role does not exist yet in RedHatOfficial repositories."
            echo "Available roles are only for RHEL 7, 8, and 9."
            echo "Using RHEL 9 STIG role as the closest available option for basic hardening."
            echo "Note: This may not cover all RHEL 10 specific requirements."
            read -p "Do you want to continue with RHEL 9 STIG role? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Exiting. Please use RHEL 8 or 9 for full STIG compliance."
                exit 1
            fi
            role_name="ansible-role-rhel9-stig"
            skip_tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-09-040110"
            ;;
        *)
            echo "Error#!/bin/bash

# Multi-OS Compliance as Code Hardening Script
# Uses ComplianceAsCode/content repository for SCAP security automation
# Supports RHEL/UBI 8, 9, and 10

set -e

# Function to detect OS version
detect_os_version() {
    if [ -f /etc/redhat-release ]; then
        OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -n1)
        echo "Detected RHEL/UBI version: $OS_VERSION"
    else
        echo "Error: Could not detect Red Hat based OS"
        exit 1
    fi
}

# Function to install common packages
install_common_packages() {
    echo "Installing common packages..."
    dnf update -y
    dnf install -y mailx postfix unzip git curl
    
    # Install appropriate Python version based on OS
    case $OS_VERSION in
        8)
            dnf install -y python3.11-pip
            PYTHON_CMD="python3.11"
            ;;
        9)
            dnf install -y python3-pip
            PYTHON_CMD="python3"
            ;;
        10)
            dnf install -y python3-pip
            PYTHON_CMD="python3"
            ;;
        *)
            echo "Error: Unsupported OS version: $OS_VERSION"
            echo "Supported versions: RHEL/UBI 8, 9, 10"
            exit 1
            ;;
    esac
    
    # Upgrade pip and install Ansible
    $PYTHON_CMD -m pip install --upgrade pip
    $PYTHON_CMD -m pip install ansible ansible-core
}

# Function to create appropriate playbook
create_playbook() {
    local playbook_file=""
    local skip_tags=""
    
    case $OS_VERSION in
        8)
            playbook_file="rhel8-playbook-stig.yml"
            skip_tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-08-040110"
            ;;
        9)
            playbook_file="rhel9-playbook-stig.yml"
            skip_tags="sudo_remove_no_authenticate,sudo_remove_nopasswd,sudoers_default_includedir,sudo_require_reauthentication,sudoers_validate_passwd,package_rng-tools_installed,enable_authselect,DISA-STIG-RHEL-09-040110"
            ;;
        10)
            echo "Error: RHEL 10 STIG playbook is not available from ComplianceAsCode/content."
            echo "Only RHEL 8 and 9 STIG playbooks are currently supported."
            echo "Please use RHEL 8 or 9 for STIG compliance hardening."
            exit 1
            ;;
        *)
            echo "Error: Unsupported OS version: $OS_VERSION"
            echo "Supported versions: RHEL/UBI 8, 9"
            exit 1
            ;;
    esac
    
    echo "Using STIG playbook: $playbook_file"
    echo "Skip tags: $skip_tags"
    
    # Export variables for use in run_hardening function
    export PLAYBOOK_FILE=$playbook_file
    export SKIP_TAGS=$skip_tags
}

# Function to get latest release info from GitHub API
get_latest_release() {
    local repo_name="content"
    local api_url="https://api.github.com/repos/ComplianceAsCode/content/releases/latest"
    
    echo "Fetching latest release info for ComplianceAsCode/content..."
    
    # Get release info using curl
    local release_info=$(curl -s "$api_url")
    
    # Extract tag name and download URL
    local tag_name=$(echo "$release_info" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    local download_url=$(echo "$release_info" | grep '"zipball_url":' | sed -E 's/.*"zipball_url": "([^"]+)".*/\1/')
    
    if [ -z "$tag_name" ] || [ -z "$download_url" ]; then
        echo "Error: Could not fetch release information for ComplianceAsCode/content"
        echo "API Response: $release_info"
        return 1
    fi
    
    echo "Latest release: $tag_name"
    echo "Download URL: $download_url"
    
    # Export for use in calling function
    export RELEASE_TAG=$tag_name
    export DOWNLOAD_URL=$download_url
}

# Function to download and extract release
download_and_extract_release() {
    local zip_file="ComplianceAsCode-content-${RELEASE_TAG}.zip"
    
    echo "Downloading release archive: $zip_file"
    curl -L -o "$zip_file" "$DOWNLOAD_URL"
    
    if [ ! -f "$zip_file" ]; then
        echo "Error: Failed to download $zip_file"
        return 1
    fi
    
    echo "Extracting $zip_file..."
    unzip -q "$zip_file"
    
    # Find the extracted directory (GitHub creates directories with commit hash)
    local extracted_dir=$(find . -maxdepth 1 -type d -name "ComplianceAsCode-content-*" | head -n1)
    
    if [ -z "$extracted_dir" ]; then
        echo "Error: Could not find extracted directory"
        return 1
    fi
    
    # Rename to expected directory name
    mv "$extracted_dir" "ComplianceAsCode-content"
    
    echo "Successfully extracted to: ComplianceAsCode-content"
    
    # Cleanup zip file
    rm -f "$zip_file"
}

# Function to run hardening
run_hardening() {
    echo "Setting up virtual environment and running hardening..."
    
    # Create virtual environment
    $PYTHON_CMD -m venv ansibletemp
    
    # Activate venv and run hardening
    source ansibletemp/bin/activate
    
    # Upgrade pip in venv
    python3 -m pip install --upgrade pip
    python3 -m pip install ansible ansible-core
    
    # Get latest release and download ComplianceAsCode content
    if get_latest_release; then
        download_and_extract_release
    else
        echo "Error: Failed to get release information. Falling back to git clone..."
        local repo_url="https://github.com/ComplianceAsCode/content.git"
        echo "Cloning from main branch: $repo_url"
        git clone "$repo_url" ComplianceAsCode-content
    fi
    
    # Verify content directory exists
    if [ ! -d "ComplianceAsCode-content" ]; then
        echo "Error: ComplianceAsCode-content directory not found"
        exit 1
    fi
    
    # Verify the specific playbook exists
    local playbook_path="ComplianceAsCode-content/products/rhel${OS_VERSION}/playbooks/$PLAYBOOK_FILE"
    if [ ! -f "$playbook_path" ]; then
        echo "Error: Playbook not found at: $playbook_path"
        echo "Available playbooks in ComplianceAsCode-content/products/rhel${OS_VERSION}/playbooks/:"
        ls -la "ComplianceAsCode-content/products/rhel${OS_VERSION}/playbooks/" || echo "Directory not found"
        exit 1
    fi
    
    # Run the playbook
    echo "Running hardening playbook: $playbook_path"
    echo "Release version: ${RELEASE_TAG:-main}"
    ansible-playbook -i "localhost," -c local "$playbook_path" --skip-tags="$SKIP_TAGS"
    
    # Deactivate virtual environment
    deactivate
}

# Function to set crypto policies
set_crypto_policies() {
    echo "Setting crypto policies to FIPS..."
    
    case $OS_VERSION in
        8|9|10)
            update-crypto-policies --set FIPS
            echo "FIPS crypto policy set successfully"
            ;;
        *)
            echo "Error: Crypto policy setting not supported for OS version $OS_VERSION"
            echo "Supported versions: RHEL/UBI 8, 9, 10"
            exit 1
            ;;
    esac
}

# Function to display summary
display_summary() {
    echo ""
    echo "==============================================="
    echo "Hardening Summary"
    echo "==============================================="
    echo "OS Version: RHEL/UBI $OS_VERSION"
    echo "Python Command: $PYTHON_CMD"
    echo "Repository: ComplianceAsCode/content"
    echo "Playbook: $PLAYBOOK_FILE"
    echo "Release Version: ${RELEASE_TAG:-main}"
    echo "Crypto Policy: FIPS"
    echo "==============================================="
    echo "Hardening completed successfully!"
}

# Function to cleanup
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf ansibletemp
}

# Main execution
main() {
    echo "Starting multi-OS compliance hardening..."
    
    detect_os_version
    install_common_packages
    create_playbook
    run_hardening
    set_crypto_policies
    display_summary
    
    # Cleanup on successful completion
    trap cleanup EXIT
}

# Run main function
main "$@"
