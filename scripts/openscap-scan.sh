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

# Run the OpenSCAP scan with volume mount
echo "Creating and running scan container..."
docker run --name "$TEMP_CONTAINER" \
    --user root \
    --workdir /tmp \
    --volume "$(pwd)/$OUTPUT_DIR:/output" \
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
            --results /output/oscap-report.xml \\
            --report /output/openscap.html \\
            --oval-results \"\$SCAP_FILE\" 2>&1 || true
        
        echo 'Converting XCCDF results to JUnit format...'
        # Convert XCCDF to JUnit XML format for GitHub Actions
        python3 -c \"
import xml.etree.ElementTree as ET
import sys
from datetime import datetime

try:
    # Parse the XCCDF results
    tree = ET.parse('/output/oscap-report.xml')
    root = tree.getroot()
    
    # Define namespaces
    ns = {'xccdf': 'http://checklists.nist.gov/xccdf/1.2'}
    
    # Create JUnit XML structure
    junit_root = ET.Element('testsuites')
    junit_root.set('name', 'OpenSCAP Security Scan')
    junit_root.set('time', '0')
    
    testsuite = ET.SubElement(junit_root, 'testsuite')
    testsuite.set('name', 'OpenSCAP STIG Profile')
    testsuite.set('timestamp', datetime.now().isoformat())
    
    # Count results
    pass_count = 0
    fail_count = 0
    error_count = 0
    skip_count = 0
    
    # Process rule results
    for rule_result in root.findall('.//xccdf:rule-result', ns):
        rule_id = rule_result.get('idref', 'unknown-rule')
        result = rule_result.find('xccdf:result', ns)
        
        if result is not None:
            result_text = result.text
            
            # Create test case
            testcase = ET.SubElement(testsuite, 'testcase')
            testcase.set('classname', 'OpenSCAP.STIG')
            testcase.set('name', rule_id.split('_')[-1] if '_' in rule_id else rule_id)
            testcase.set('time', '0')
            
            if result_text == 'pass':
                pass_count += 1
            elif result_text == 'fail':
                fail_count += 1
                failure = ET.SubElement(testcase, 'failure')
                failure.set('message', f'Security rule {rule_id} failed')
                failure.text = f'Rule {rule_id} did not pass the security check'
            elif result_text == 'error':
                error_count += 1
                error_elem = ET.SubElement(testcase, 'error')
                error_elem.set('message', f'Error evaluating rule {rule_id}')
                error_elem.text = f'An error occurred while evaluating rule {rule_id}'
            else:  # notapplicable, unknown, etc.
                skip_count += 1
                skipped = ET.SubElement(testcase, 'skipped')
                skipped.set('message', f'Rule {rule_id} was {result_text}')
    
    # Set testsuite attributes
    total_tests = pass_count + fail_count + error_count + skip_count
    testsuite.set('tests', str(total_tests))
    testsuite.set('failures', str(fail_count))
    testsuite.set('errors', str(error_count))
    testsuite.set('skipped', str(skip_count))
    testsuite.set('time', '0')
    
    junit_root.set('tests', str(total_tests))
    junit_root.set('failures', str(fail_count))
    junit_root.set('errors', str(error_count))
    junit_root.set('skipped', str(skip_count))
    
    # Write JUnit XML
    junit_tree = ET.ElementTree(junit_root)
    ET.indent(junit_tree, space='  ', level=0)
    junit_tree.write('/output/junit-results.xml', encoding='utf-8', xml_declaration=True)
    
    print(f'Conversion complete: {total_tests} tests ({pass_count} passed, {fail_count} failed, {error_count} errors, {skip_count} skipped)')
    
except Exception as e:
    print(f'Error converting to JUnit format: {e}')
    # Create a minimal JUnit file to prevent workflow errors
    minimal_junit = '''<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>
<testsuites name=\\\"OpenSCAP Security Scan\\\" tests=\\\"1\\\" failures=\\\"0\\\" errors=\\\"1\\\" skipped=\\\"0\\\">
  <testsuite name=\\\"OpenSCAP STIG Profile\\\" tests=\\\"1\\\" failures=\\\"0\\\" errors=\\\"1\\\" skipped=\\\"0\\\">
    <testcase classname=\\\"OpenSCAP.Conversion\\\" name=\\\"XMLConversion\\\" time=\\\"0\\\">
      <error message=\\\"Failed to convert XCCDF to JUnit\\\">Failed to parse OpenSCAP results for JUnit conversion</error>
    </testcase>
  </testsuite>
</testsuites>'''
    with open('/output/junit-results.xml', 'w') as f:
        f.write(minimal_junit)
\" || echo 'JUnit conversion failed but continuing...'
        
        echo 'Scan completed successfully'
        echo 'Results saved to /output directory'
    "

# Clean up the temporary container
echo "Cleaning up temporary container..."
docker rm "$TEMP_CONTAINER" >/dev/null

echo ""
echo "OpenSCAP scan completed successfully!"
echo "Results saved to:"
echo "  - HTML Report: $OUTPUT_DIR/openscap.html"
echo "  - XML Report: $OUTPUT_DIR/oscap-report.xml (XCCDF format)"
echo "  - JUnit Report: $OUTPUT_DIR/junit-results.xml (for GitHub Actions)"
echo ""
echo "You can view the HTML report by opening: $OUTPUT_DIR/openscap.html"