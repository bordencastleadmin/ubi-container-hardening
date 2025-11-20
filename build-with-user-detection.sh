#!/bin/bash
# Build script that detects original user and restores it after hardening

set -e

usage() {
    echo "Usage: $0 -f DOCKERFILE -t TAG [OPTIONS]"
    echo "  -f DOCKERFILE    Path to Dockerfile"
    echo "  -t TAG          Tag for built image"
    echo "  --base-image    Override base image (optional)"
    echo "  --version       ComplianceAsCode version (default: 0.1.78)"
    echo "  -h, --help      Show this help"
    exit 1
}

# Default values
COMPLIANCE_VERSION="0.1.78"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        --base-image)
            BASE_IMAGE="$2"
            shift 2
            ;;
        --version)
            COMPLIANCE_VERSION="$2"
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
if [ -z "$DOCKERFILE" ] || [ -z "$TAG" ]; then
    echo "Error: -f and -t are required"
    usage
fi

if [ ! -f "$DOCKERFILE" ]; then
    echo "Error: Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Extract base image from Dockerfile if not provided
if [ -z "$BASE_IMAGE" ]; then
    BASE_IMAGE=$(grep "^ARG BASE_IMAGE=" "$DOCKERFILE" | cut -d'=' -f2 | head -n1)
    if [ -z "$BASE_IMAGE" ]; then
        BASE_IMAGE=$(grep "^FROM " "$DOCKERFILE" | head -n1 | awk '{print $2}')
    fi
fi

echo "Base image: $BASE_IMAGE"
echo "Detecting original user..."

# Pull base image if not available
docker pull "$BASE_IMAGE"

# Detect original user
ORIGINAL_USER=$(docker inspect "$BASE_IMAGE" --format='{{.Config.User}}')

# Handle empty user (defaults to root)
if [ -z "$ORIGINAL_USER" ] || [ "$ORIGINAL_USER" = "<no value>" ]; then
    ORIGINAL_USER="0"
    echo "Base image uses root (default)"
else
    echo "Base image uses user: $ORIGINAL_USER"
fi

# Determine final user
if [ "$ORIGINAL_USER" = "0" ] || [ "$ORIGINAL_USER" = "root" ]; then
    FINAL_USER="1001"
    echo "Will create non-root user 1001"
else
    FINAL_USER="$ORIGINAL_USER"
    echo "Will restore original user: $FINAL_USER"
fi

# Build with detected user
echo "Building $TAG with final user: $FINAL_USER"
docker build -f "$DOCKERFILE" \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg COMPLIANCE_AS_CODE_VERSION="$COMPLIANCE_VERSION" \
    --build-arg FINAL_USER="$FINAL_USER" \
    --build-arg ORIGINAL_USER="$ORIGINAL_USER" \
    -t "$TAG" .

echo "Build complete: $TAG"
echo "Final user: $FINAL_USER"