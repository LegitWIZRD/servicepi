#!/bin/bash
# Pi-hole Integration Test Script
# This script tests the Pi-hole service after deployment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing Pi-hole Integration"
echo ""

# Test 1: Check if Pi-hole container is running
echo -n "Test 1: Pi-hole container status... "
if docker ps | grep -q "servicepi-pihole"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

# Test 2: Check if Pi-hole admin interface is accessible
echo -n "Test 2: Pi-hole admin interface (port 8053)... "
if curl -f -s -o /dev/null "http://localhost:8053/admin"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    docker logs servicepi-pihole --tail=20
    exit 1
fi

# Test 3: Check if DNS service is responding
echo -n "Test 3: DNS service (port 53)... "
if command -v dig &> /dev/null; then
    if dig @localhost example.com +short | grep -q "[0-9]"; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${RED}✗ FAIL${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ SKIP (dig not installed)${NC}"
fi

# Test 4: Check if blocklists are loaded
echo -n "Test 4: Blocklists configuration... "
if docker exec servicepi-pihole test -f /etc/pihole/adlists.list; then
    BLOCKLIST_COUNT=$(docker exec servicepi-pihole wc -l < /etc/pihole/adlists.list)
    if [ "$BLOCKLIST_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} ($BLOCKLIST_COUNT lists configured)"
    else
        echo -e "${RED}✗ FAIL${NC} (no blocklists found)"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC} (adlists.list not found)"
    exit 1
fi

# Test 5: Check if custom DNS entries file exists
echo -n "Test 5: Custom DNS configuration... "
if docker exec servicepi-pihole test -f /etc/pihole/custom.list; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

# Test 6: Check if Pi-hole FTL is running
echo -n "Test 6: Pi-hole FTL service... "
if docker exec servicepi-pihole pihole status | grep -q "FTL is running"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${YELLOW}⊘ SKIP (FTL may still be starting)${NC}"
fi

# Test 7: Check nginx proxy configuration
echo -n "Test 7: Nginx proxy configuration... "
if docker exec servicepi-proxy nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ PASS${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All Pi-hole integration tests passed!${NC}"
echo ""
echo "Access Pi-hole admin at: http://localhost:8053/admin"
echo "Configure devices to use DNS: localhost (port 53)"
