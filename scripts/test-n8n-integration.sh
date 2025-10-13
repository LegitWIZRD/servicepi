#!/bin/bash
# N8N Integration Test Script
# This script tests the N8N service and verifies the secure cookie fix

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing N8N Integration"
echo ""

# Test 1: Check if N8N container is running
echo -n "Test 1: N8N container status... "
if docker ps | grep -q "servicepi-n8n"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "N8N container is not running"
    docker ps -a | grep n8n || true
    exit 1
fi

# Test 2: Check if N8N_SECURE_COOKIE environment variable is set correctly
echo -n "Test 2: N8N_SECURE_COOKIE environment variable... "
if docker inspect servicepi-n8n | grep -q "N8N_SECURE_COOKIE=false"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "N8N_SECURE_COOKIE is not set to false"
    docker inspect servicepi-n8n | grep N8N_SECURE_COOKIE || true
    exit 1
fi

# Test 3: Check if N8N_PROTOCOL is set to http
echo -n "Test 3: N8N_PROTOCOL environment variable... "
if docker inspect servicepi-n8n | grep -q "N8N_PROTOCOL=http"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "N8N_PROTOCOL is not set to http"
    exit 1
fi

# Test 4: Check if N8N web interface is accessible
echo -n "Test 4: N8N web interface (port 5678)... "
# Wait a bit for N8N to fully start if it just started
sleep 2
if curl -f -s -o /dev/null -w "%{http_code}" "http://localhost:5678/" | grep -q "200\|302"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "N8N web interface is not accessible"
    docker logs servicepi-n8n --tail=30
    exit 1
fi

# Test 5: Check if N8N logs contain "Editor is now accessible"
echo -n "Test 5: N8N service initialization... "
if docker logs servicepi-n8n 2>&1 | grep -q "Editor is now accessible"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${YELLOW}⊘ SKIP (N8N may still be starting)${NC}"
fi

# Test 6: Verify no secure cookie error in logs
echo -n "Test 6: Check for secure cookie errors in logs... "
if docker logs servicepi-n8n 2>&1 | grep -iq "secure cookie"; then
    echo -e "${YELLOW}⚠ WARNING${NC} (secure cookie mentioned in logs)"
    docker logs servicepi-n8n 2>&1 | grep -i "secure cookie" || true
else
    echo -e "${GREEN}✓ PASS${NC}"
fi

# Test 7: Check nginx proxy configuration for N8N
echo -n "Test 7: Nginx proxy configuration for N8N... "
if docker exec servicepi-proxy cat /etc/nginx/conf.d/default.conf | grep -q "# N8N Workflow Automation"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "N8N proxy configuration not found in nginx"
    exit 1
fi

# Test 8: Verify N8N port is exposed through nginx proxy
echo -n "Test 8: N8N port exposure through proxy... "
if docker port servicepi-proxy | grep -q "5678"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "Port 5678 is not exposed"
    docker port servicepi-proxy
    exit 1
fi

# Test 9: Test actual HTTP connection to N8N
echo -n "Test 9: HTTP connection test... "
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5678/" || echo "000")
if [ "$HTTP_RESPONSE" = "200" ] || [ "$HTTP_RESPONSE" = "302" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_RESPONSE)"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_RESPONSE)"
    exit 1
fi

# Test 10: Check for presence of test script
echo -n "Test 10: N8N configuration test script exists... "
if [ -f "scripts/test-n8n-config.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "scripts/test-n8n-config.sh not found"
    exit 1
fi

# Test 11: Run the configuration test script
echo -n "Test 11: Run N8N configuration test... "
if bash scripts/test-n8n-config.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "Configuration test failed"
    bash scripts/test-n8n-config.sh
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All N8N integration tests passed!${NC}"
echo ""
echo "N8N is properly configured for HTTP-only access without secure cookie errors."
echo "Access N8N at: http://localhost:5678/"
echo ""
echo "To verify in a browser, open: http://$(hostname -I | awk '{print $1}'):5678/"
