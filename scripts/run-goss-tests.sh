#!/bin/bash
# Goss test runner for container user validation
# Maps container types to appropriate test files

set -e

usage() {
    echo "Usage: $0 --container CONTAINER_IMAGE --container-name CONTAINER_NAME"
    echo "  --container      Container image to test"
    echo "  --container-name Name/type of container (for test selection)"
    echo "  --goss-version   Goss version (default: 0.4.4)"
    echo "  -h, --help       Show this help"
    exit 1
}

# Default values
GOSS_VERSION="0.4.4"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --container)
            CONTAINER_IMAGE="$2"
            shift 2
            ;;
        --container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --goss-version)
            GOSS_VERSION="$2"
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

# Validate required arguments
if [ -z "$CONTAINER_IMAGE" ] || [ -z "$CONTAINER_NAME" ]; then
    echo "Error: --container and --container-name are required"
    usage
fi

# Map container names to test files
select_test_file() {
    case "$CONTAINER_NAME" in
        *python-39*|*python-311*)
            if [[ "$CONTAINER_NAME" == ubi* ]]; then
                echo "tests/goss-ubi-python.yaml"
            else
                echo "tests/goss-ubuntu-python.yaml"
            fi
            ;;
        *openjdk*)
            echo "tests/goss-ubi-openjdk.yaml"
            ;;
        ubi*|*ubi*)
            echo "tests/goss-ubi-base.yaml"
            ;;
        ubuntu*|*ubuntu*)
            if [[ "$CONTAINER_NAME" == *python* ]]; then
                echo "tests/goss-ubuntu-python.yaml"
            else
                echo "tests/goss-ubuntu-custom.yaml"
            fi
            ;;
        *)
            echo "tests/goss-ubi-base.yaml"  # Default fallback
            ;;
    esac
}

TEST_FILE=$(select_test_file)

echo "Container: $CONTAINER_IMAGE"
echo "Container name: $CONTAINER_NAME"
echo "Selected test file: $TEST_FILE"

if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Test file not found: $TEST_FILE"
    exit 1
fi

# Download goss if not available
if ! command -v goss &> /dev/null; then
    echo "Downloading goss v${GOSS_VERSION}..."
    curl -fsSL "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64" -o goss
    chmod +x goss
    GOSS_CMD="./goss"
else
    GOSS_CMD="goss"
fi

echo "Running goss tests for $CONTAINER_NAME..."
echo "=========================================="

# Run goss tests in the container
docker run --rm -v "$(pwd)/$TEST_FILE:/goss.yaml:ro" \
    -v "$(pwd)/goss:/usr/local/bin/goss:ro" \
    --entrypoint="" \
    "$CONTAINER_IMAGE" \
    /usr/local/bin/goss validate --format documentation

echo ""
echo "Goss tests completed for $CONTAINER_NAME"