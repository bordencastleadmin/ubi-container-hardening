#!/bin/bash

# OpenSCAP Docker Container Scanning Script
# This script runs OpenSCAP security scanning on a Docker container

set -e

# Function to display usage
usage() {
    echo "Usage: $0 --container <container_image> --compliance-version <version> [--output-dir <dir>]"
    echo ""
    echo "Options:"
    echo "  --container <image>           Docker container image to scan"
    echo "  --compliance-version <ver>    Compliance as Code version (e.g., 0.1.77)"
    echo "  --output-dir <dir>           Output directory for scan results (default: ./openscap-output)"
    echo "  --help                       Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 --container localbuild/ubi8:latest --compliance-version 0.1.77"
    exit 1
}

# Parse command line arguments
CONTAINER=""
COMPLIANCE_AS_CODE_VERSION=""
OUTPUT_DIR="./openscap-output"

while [[ $# -gt 0 ]]; do
    case $1 in
        --container)
            CONTAINER="$2"
            shift 2
            ;;
        --compliance-version)
            COMPLIANCE_AS_CODE_VERSION="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$CONTAINER" ]]; then
    echo "Error: --container is required"
    usage
fi

if [[ -z "$COMPLIANCE_AS_CODE_VERSION" ]]; then
    echo "Error: --compliance-version is required"
    usage
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Starting OpenSCAP scan for container: $CONTAINER"
echo "Using Compliance as Code version: $COMPLIANCE_AS_CODE_VERSION"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create a temporary container name
TEMP_CONTAINER="openscap-scan-$(date +%s)"

# Run the OpenSCAP scan
echo "Creating and running scan container..."
docker run --name "$TEMP_CONTAINER" \
    --user root \
    --workdir /tmp \
    "$CONTAINER" \
    bash -c "
        set -e
        echo 'Installing required tools...'
        dnf install -y openscap-scanner unzip wget
        
        echo 'Downloading SCAP Security Guide...'
        wget -O /tmp/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}.zip https://github.com/ComplianceAsCode/content/releases/download/v${COMPLIANCE_AS_CODE_VERSION}/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}.zip
        
        echo 'Extracting SCAP Security Guide...'
        unzip -q /tmp/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}.zip
        
        echo 'Detecting OS version and running scan...'
        source /etc/os-release
        case \"\$VERSION_ID\" in
            8*)
                SCAP_FILE=\"/tmp/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}/ssg-rhel8-ds.xml\"
                ;;
            9*)
                SCAP_FILE=\"/tmp/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}/ssg-rhel9-ds.xml\"
                ;;
            10*)
                SCAP_FILE=\"/tmp/scap-security-guide-${COMPLIANCE_AS_CODE_VERSION}/ssg-rhel10-ds.xml\"
                ;;
            *)
                echo \"Unsupported OS version: \$VERSION_ID\"
                exit 1
                ;;
        esac
        
        echo \"Using SCAP file: \$SCAP_FILE\"
        echo \"Running OpenSCAP evaluation...\"
        
        oscap xccdf eval \\
            --profile xccdf_org.ssgproject.content_profile_stig \\
            --results /tmp/oscap-report.xml \\
            --report /tmp/openscap.html \\
            --oval-results \"\$SCAP_FILE\" 2>&1 || true
        
        echo 'Scan completed successfully'
    "

# Extract the results from the container
echo ""
echo "Extracting scan results..."
docker cp "$TEMP_CONTAINER:/tmp/openscap.html" "$OUTPUT_DIR/openscap.html"
docker cp "$TEMP_CONTAINER:/tmp/oscap-report.xml" "$OUTPUT_DIR/oscap-report.xml" 2>/dev/null || echo "Note: oscap-report.xml not found (this is normal)"

# Clean up the temporary container
echo "Cleaning up temporary container..."
docker rm "$TEMP_CONTAINER" >/dev/null

echo ""
echo "OpenSCAP scan completed successfully!"
echo "Results saved to:"
echo "  - HTML Report: $OUTPUT_DIR/openscap.html"
echo "  - XML Report: $OUTPUT_DIR/oscap-report.xml"
echo ""
echo "You can view the HTML report by opening: $OUTPUT_DIR/openscap.html"
