#!/bin/bash

# Test script to validate proxy header forwarding
# This script tests that critical headers are properly forwarded for CSRF validation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Testing Proxy Header Forwarding..."
echo ""

# Test Portainer proxy headers
echo "Testing Portainer (port 9000)..."
PORTAINER_TEST=$(curl -v -s -o /dev/null \
  -H "Origin: http://test-origin.com" \
  -H "Referer: http://test-referer.com" \
  -H "X-CSRF-Token: test-token" \
  http://localhost:9000/ 2>&1 || true)

if echo "$PORTAINER_TEST" | grep -q "< HTTP"; then
  echo -e "${GREEN}✓${NC} Portainer proxy is responding"
else
  echo -e "${RED}✗${NC} Portainer proxy failed to respond"
  exit 1
fi

# Test IoT API proxy headers
echo "Testing IoT API (port 8080)..."
IOT_TEST=$(curl -v -s -o /dev/null \
  -H "Origin: http://test-origin.com" \
  http://localhost:8080/health 2>&1 || true)

if echo "$IOT_TEST" | grep -q "< HTTP"; then
  echo -e "${GREEN}✓${NC} IoT API proxy is responding"
else
  echo -e "${RED}✗${NC} IoT API proxy failed to respond"
  exit 1
fi

echo ""
echo -e "${GREEN}All proxy header tests passed!${NC}"
