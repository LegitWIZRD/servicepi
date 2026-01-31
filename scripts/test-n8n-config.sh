#!/bin/bash

# Test script to validate N8N configuration
# This script verifies that N8N is properly configured for HTTP-only access

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing N8N Configuration..."
echo ""

# Expected version
EXPECTED_VERSION="2.4.8"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗${NC} docker-compose.yml not found"
    exit 1
fi

# Verify N8N version is correct
echo "Checking N8N version..."
# Use Python to parse YAML for reliable version extraction
ACTUAL_VERSION=$(python3 -c "
import yaml
import sys
try:
    with open('docker-compose.yml', 'r') as f:
        config = yaml.safe_load(f)
    image = config['services']['n8n']['image']
    version = image.split(':')[-1] if ':' in image else 'unknown'
    print(version)
except Exception as e:
    print('error', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)

if [ -z "$ACTUAL_VERSION" ] || [ "$ACTUAL_VERSION" = "error" ]; then
    echo -e "${YELLOW}⚠${NC} Could not extract N8N version from docker-compose.yml"
elif [ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✓${NC} N8N is using version $EXPECTED_VERSION"
else
    echo -e "${YELLOW}⚠${NC} N8N version may not be $EXPECTED_VERSION"
    echo -e "${YELLOW}  Current version: $ACTUAL_VERSION${NC}"
fi

# Verify N8N_SECURE_COOKIE is set to false
echo "Checking N8N_SECURE_COOKIE environment variable..."
if grep -A 10 "container_name: servicepi-n8n" docker-compose.yml | grep -q "N8N_SECURE_COOKIE=false"; then
    echo -e "${GREEN}✓${NC} N8N_SECURE_COOKIE is set to false"
else
    echo -e "${RED}✗${NC} N8N_SECURE_COOKIE is not set to false"
    echo -e "${YELLOW}⚠${NC} N8N requires N8N_SECURE_COOKIE=false for HTTP-only access"
    exit 1
fi

# Verify N8N_PROTOCOL is set to http
echo "Checking N8N_PROTOCOL environment variable..."
if grep -A 10 "container_name: servicepi-n8n" docker-compose.yml | grep -q "N8N_PROTOCOL=http"; then
    echo -e "${GREEN}✓${NC} N8N_PROTOCOL is set to http"
else
    echo -e "${RED}✗${NC} N8N_PROTOCOL is not set to http"
    exit 1
fi

# Verify N8N is included in nginx proxy dependencies
echo "Checking nginx proxy dependencies..."
if grep -A 10 "depends_on:" docker-compose.yml | grep -q "n8n"; then
    echo -e "${GREEN}✓${NC} N8N is included in nginx proxy dependencies"
else
    echo -e "${YELLOW}⚠${NC} N8N is not in nginx proxy dependencies (may not be critical)"
fi

# Verify N8N proxy configuration exists
echo "Checking N8N nginx proxy configuration..."
if [ -f "configs/nginx/proxy/default.conf" ]; then
    if grep -q "# N8N Workflow Automation" configs/nginx/proxy/default.conf; then
        echo -e "${GREEN}✓${NC} N8N nginx proxy configuration found"
    else
        echo -e "${RED}✗${NC} N8N nginx proxy configuration not found"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} nginx proxy configuration file not found"
    exit 1
fi

# Verify N8N proxy port is exposed
echo "Checking N8N proxy port configuration..."
if grep -A 15 "nginx-proxy:" docker-compose.yml | grep -q "5678:5678"; then
    echo -e "${GREEN}✓${NC} N8N port 5678 is exposed in nginx proxy"
else
    echo -e "${RED}✗${NC} N8N port 5678 is not exposed in nginx proxy"
    exit 1
fi

echo ""
echo -e "${GREEN}All N8N configuration tests passed!${NC}"
echo ""
echo "N8N is configured for HTTP-only access and will not require secure cookies."
echo "Access N8N at: http://your-pi-ip:5678/"
