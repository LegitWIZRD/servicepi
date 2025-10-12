#!/bin/bash

# Test script to validate Home Assistant trusted proxies configuration
# This script verifies that the configuration covers the full Docker bridge network range

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Testing Home Assistant Trusted Proxies Configuration..."
echo ""

CONFIG_FILE="configs/homeassistant/configuration.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}✗${NC} Configuration file not found: $CONFIG_FILE"
  exit 1
fi

echo "Checking trusted_proxies configuration..."

# Check for 172.16.0.0/12 (Docker bridge network range)
if grep -q "172.16.0.0/12" "$CONFIG_FILE"; then
  echo -e "${GREEN}✓${NC} Docker bridge network range (172.16.0.0/12) is configured"
else
  echo -e "${RED}✗${NC} Docker bridge network range (172.16.0.0/12) is NOT configured"
  echo -e "${YELLOW}⚠${NC}  This may cause issues when Docker assigns IPs from different subnets"
  exit 1
fi

# Check for 192.168.0.0/16 (Local network range)
if grep -q "192.168.0.0/16" "$CONFIG_FILE"; then
  echo -e "${GREEN}✓${NC} Local network range (192.168.0.0/16) is configured"
else
  echo -e "${YELLOW}⚠${NC}  Local network range (192.168.0.0/16) is not configured"
fi

# Check for 10.0.0.0/8 (Private network range)
if grep -q "10.0.0.0/8" "$CONFIG_FILE"; then
  echo -e "${GREEN}✓${NC} Private network range (10.0.0.0/8) is configured"
else
  echo -e "${YELLOW}⚠${NC}  Private network range (10.0.0.0/8) is not configured"
fi

# Verify use_x_forwarded_for is enabled
if grep -q "use_x_forwarded_for: true" "$CONFIG_FILE"; then
  echo -e "${GREEN}✓${NC} use_x_forwarded_for is enabled"
else
  echo -e "${RED}✗${NC} use_x_forwarded_for is NOT enabled"
  exit 1
fi

# Validate YAML syntax
echo ""
echo "Validating YAML syntax..."
if command -v python3 &> /dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" 2>&1; then
    echo -e "${GREEN}✓${NC} YAML syntax is valid"
  else
    echo -e "${RED}✗${NC} YAML syntax is invalid"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠${NC}  Python3 not available, skipping YAML validation"
fi

echo ""
echo -e "${GREEN}All Home Assistant configuration tests passed!${NC}"
echo ""
echo "Network ranges covered:"
echo "  - 172.16.0.0/12  (Docker bridge: 172.16.0.0 - 172.31.255.255)"
echo "  - 192.168.0.0/16 (Local network: 192.168.0.0 - 192.168.255.255)"
echo "  - 10.0.0.0/8     (Private network: 10.0.0.0 - 10.255.255.255)"
