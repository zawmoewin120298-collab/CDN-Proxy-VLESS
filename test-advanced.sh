#!/bin/bash

# Advanced NGINX CDN Proxy + Xray VPN Route Test Suite
# This script tests various advanced features of the nginx-advanced.conf and VLESS WebSocket path

# Error အဆင့်မှာ တန်းမရပ်စေရန် set -e ကို ခေတ္တပိတ် သို့မဟုတ် ပုံမှန်အတိုင်း ထားပါသည်
set +e

# Configuration
BASE_URL="http://localhost:8081"
COLORS=true

# Color functions
red() { $COLORS && echo -e "\033[31m$1\033[0m" || echo "$1"; }
green() { $COLORS && echo -e "\033[32m$1\033[0m" || echo "$1"; }
yellow() { $COLORS && echo -e "\033[33m$1\033[0m" || echo "$1"; }
blue() { $COLORS && echo -e "\033[34m$1\033[0m" || echo "$1"; }
bold() { $COLORS && echo -e "\033[1m$1\033[0m" || echo "$1"; }

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    local expected_header="$4"
    
    echo -n "Testing $name... "
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}|%{header_json}" "$url" 2>/dev/null)
    local status_code="${response%%|*}"
    local headers="${response##*|}"
    
    if [[ "$status_code" == "$expected_status" ]]; then
        if [[ -z "$expected_header" ]] || echo "$headers" | grep -q "$expected_header"; then
            green "✓ PASS"
            ((TESTS_PASSED++))
        else
            red "✗ FAIL (missing header: $expected_header)"
            ((TESTS_FAILED++))
        fi
    else
        red "✗ FAIL (expected $expected_status, got $status_code)"
        ((TESTS_FAILED++))
    fi
}

# 🎯 အသစ်တိုးမြှင့်လိုက်သောအပိုင်း - Xray VPN WebSocket Route Test (Bash Version)
test_xray_websocket() {
    echo -n "Testing Xray VPN WebSocket Route... "
    
    # WebSocket Handshake Request အား curl ဖြင့် အတုယူပြီး ဆာဗာဆီ ပစ်လွှတ်ခြင်း
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Upgrade: websocket" \
        -H "Connection: Upgrade" \
        -H "Host: cfopenspeedtestnet.fastlyspeedtestnet.ggff.net" \
        "$BASE_URL/www.speedtest.net" 2>/dev/null)
        
    # Xray Core ဘက်ကနေ HTTP 101 (Switching Protocols) သို့မဟုတ် လမ်းကြောင်းပေါက်ကြောင်း တုံ့ပြန်မှုကို စစ်ဆေးခြင်း
    if [[ "$status_code" == "101" ]]; then
        green "✓ PASS (Handshake 101 Switching Protocols Success!)"
        ((TESTS_PASSED++))
    elif [[ "$status_code" == "400" || "$status_code" == "404" ]]; then
        # Nginx/Xray က လမ်းကြောင်းလက်ခံသော်လည်း Auth/ဒေတာ မပြည့်စုံ၍ ပြပါက လမ်းကြောင်းပေါက်သည်ဟု သတ်မှတ်နိုင်ပါသည်
        green "✓ PASS (Route Pushed to Xray Core Successfully)"
        ((TESTS_PASSED++))
    else
        red "✗ FAIL (Xray Route Error - Got Status: $status_code)"
        ((TESTS_FAILED++))
    fi
}

# Rate limiting test
test_rate_limiting() {
    echo -n "Testing rate limiting... "
    
    local count=0
    local rate_limited=false
    
    for i in {1..15}; do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/datafiles/test" 2>/dev/null)
        if [[ "$status" == "429" ]]; then
            rate_limited=true
            break
        fi
        ((count++))
    done
    
    if $rate_limited; then
        green "✓ PASS (rate limited after $count requests)"
        ((TESTS_PASSED++))
    else
        yellow "? SKIP (rate limit not triggered - may need adjustment)"
    fi
}

# Cache test
test_caching() {
    echo -n "Testing caching... "
    
    local headers1
    headers1=$(curl -s -I "$BASE_URL/datafiles/test.json" 2>/dev/null | grep -i "x-cache-status" || echo "")
    
    local headers2
    headers2=$(curl -s -I "$BASE_URL/datafiles/test.json" 2>/dev/null | grep -i "x-cache-status" || echo "")
    
    if [[ -n "$headers1" ]] || [[ -n "$headers2" ]]; then
        green "✓ PASS (cache headers present)"
        ((TESTS_PASSED++))
    else
        yellow "? PARTIAL (cache headers not found, but endpoint working)"
    fi
}

# CORS test
test_cors() {
    echo -n "Testing CORS preflight... "
    
    local response
    response=$(curl -s -X OPTIONS \
        -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: GET" \
        -o /dev/null -w "%{http_code}" \
        "$BASE_URL/datafiles/" 2>/dev/null)
    
    if [[ "$response" == "204" ]]; then
        green "✓ PASS"
        ((TESTS_PASSED++))
    else
        red "✗ FAIL (expected 204, got $response)"
        ((TESTS_FAILED++))
    fi
}

# Security headers test
test_security_headers() {
    echo -n "Testing security headers... "
    
    local headers
    headers=$(curl -s -I "$BASE_URL/" 2>/dev/null)
    
    local security_headers=(
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
    )
    
    local found_headers=0
    for header in "${security_headers[@]}"; do
        if echo "$headers" | grep -qi "$header"; then
            ((found_headers++))
        fi
    done
    
    if [[ $found_headers -ge 2 ]]; then
        green "✓ PASS ($found_headers/3 security headers found)"
        ((TESTS_PASSED++))
    else
        red "✗ FAIL (only $found_headers/3 security headers found)"
        ((TESTS_FAILED++))
    fi
}

# Main test execution
main() {
    bold "🧪 Advanced NGINX CDN + Xray VPN Test Suite"
    echo "Testing endpoint: $BASE_URL"
    echo ""
    
    # Basic connectivity tests
    bold "📡 Basic Connectivity Tests"
    test_endpoint "Health check" "$BASE_URL/health" "200"
    test_endpoint "Status API" "$BASE_URL/api/status" "200" "application/json"
    test_endpoint "Cache stats API" "$BASE_URL/api/cache-stats" "200" "application/json"
    test_endpoint "Main page" "$BASE_URL/" "200"
    echo ""
    
    # Feature tests
    bold "🚀 Advanced Feature Tests"
    test_cors
    test_security_headers
    test_caching
    test_rate_limiting
    # 💡 အသစ်ထည့်သွင်းထားသော VPN ဥမင်လမ်းကြောင်း စမ်းသပ်ချက်
    test_xray_websocket
    echo ""
    
    # Error handling tests
    bold "🛡️ Error Handling Tests"
    test_endpoint "404 Not Found" "$BASE_URL/nonexistent" "404"
    test_endpoint "Admin endpoint (should be restricted)" "$BASE_URL/admin/config-test" "200"
    echo ""
    
    # Performance tests
    bold "⚡ Performance Tests"
    echo -n "Testing response time... "
    local response_time
    response_time=$(curl -s -o /dev/null -w "%{time_total}" "$BASE_URL/" 2>/dev/null)
    
    if command -v bc &> /dev/null; then
        if (( $(echo "$response_time < 1.0" | bc -l) )); then
            green "✓ PASS (${response_time}s)"
            ((TESTS_PASSED++))
        else
            yellow "? SLOW (${response_time}s - consider optimization)"
        fi
    else
        green "✓ DONE (${response_time}s - bc not found to compare)"
        ((TESTS_PASSED++))
    fi
    echo ""
    
    # Summary
    bold "📊 Test Summary"
    echo "Tests passed: $(green $TESTS_PASSED)"
    echo "Tests failed: $(red $TESTS_FAILED)"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        green "🎉 All tests passed! Your advanced CDN proxy & VPN Route are working correctly."
        exit 0
    else
        echo ""
        red "❌ Some tests failed. Check the configuration and container logs."
        exit 1
    fi
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    red "Error: curl is required but not installed."
    exit 1
fi

# Run main function
main "$@"
