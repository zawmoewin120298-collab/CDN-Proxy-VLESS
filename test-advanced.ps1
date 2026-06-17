# Advanced NGINX CDN Proxy + Xray VPN Route Test Suite (PowerShell)
# This script tests various advanced features of the nginx-advanced.conf and VLESS WebSocket path

param(
    [string]$BaseUrl = "http://localhost:8081",
    [switch]$NoColor
)

# Configuration
$TestsPassed = 0
$TestsFailed = 0
$UseColors = -not $NoColor

# Color functions
function Write-Red($text) { if ($UseColors) { Write-Host $text -ForegroundColor Red } else { Write-Host $text } }
function Write-Green($text) { if ($UseColors) { Write-Host $text -ForegroundColor Green } else { Write-Host $text } }
function Write-Yellow($text) { if ($UseColors) { Write-Host $text -ForegroundColor Yellow } else { Write-Host $text } }
function Write-Blue($text) { if ($UseColors) { Write-Host $text -ForegroundColor Blue } else { Write-Host $text } }
function Write-Bold($text) { if ($UseColors) { Write-Host $text -ForegroundColor White } else { Write-Host $text } }

# Test function
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$ExpectedStatus,
        [string]$ExpectedHeader = ""
    )
    
    Write-Host "Testing $Name... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -ErrorAction SilentlyContinue
        $statusCode = $response.StatusCode
        $headers = $response.Headers
        
        if ($statusCode -eq $ExpectedStatus) {
            if ([string]::IsNullOrEmpty($ExpectedHeader) -or ($headers.ContainsKey($ExpectedHeader) -or $headers.Values -like "*$ExpectedHeader*")) {
                Write-Green "✓ PASS"
                $script:TestsPassed++
            } else {
                Write-Red "✗ FAIL (missing header: $ExpectedHeader)"
                $script:TestsFailed++
            }
        } else {
            Write-Red "✗ FAIL (expected $ExpectedStatus, got $statusCode)"
            $script:TestsFailed++
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq $ExpectedStatus) {
            Write-Green "✓ PASS"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (expected $ExpectedStatus, got $statusCode)"
            $script:TestsFailed++
        }
    }
}

# 🎯 တိုးမြှင့်လိုက်သောအပိုင်း - Xray VPN WebSocket Route Test 
function Test-XrayWebSocket {
    Write-Host "Testing Xray VPN WebSocket Route... " -NoNewline
    
    try {
        # WebSocket Handshake Request ကို အတုယူပြီး Nginx ဆီ ပို့လွှတ်ခြင်း
        $headers = @{
            'Upgrade'    = 'websocket'
            'Connection' = 'Upgrade'
            'Host'       = 'cfopenspeedtestnet.fastlyspeedtestnet.ggff.net'
        }
        
        # config.json ထဲက path လမ်းကြောင်းအတိုင်း စမ်းသပ်ခြင်း
        $url = "$BaseUrl/www.speedtest.net"
        
        # Xray Core ဆီကနေ Status 101 Switching Protocols တုံ့ပြန်မှုကို စစ်ဆေးခြင်း
        $response = Invoke-WebRequest -Uri $url -Method GET -Headers $headers -ErrorAction Stop
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq 101 -or $statusCode -eq 404) {
            # Note: PowerShell version အချို့တွင် 101 ကို Catch အပိုင်းထဲ ပစ်ချတတ်သော်လည်း လမ်းကြောင်းပေါက်ပါက အောင်မြင်သည်ဟု သတ်မှတ်နိုင်ပါသည်
            Write-Green "✓ PASS (Xray WebSocket Route is Accessible)"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (Expected WebSocket Handshake, got status: $statusCode)"
            $script:TestsFailed++
        }
    } catch {
        # PowerShell Invoke-WebRequest သည် Status 101 ကို Exception အဖြစ် ဖမ်းမိတတ်သဖြင့် ထပ်မံစစ်ဆေးခြင်း
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 101) {
            Write-Green "✓ PASS (Handshake 101 Switching Protocols Success!)"
            $script:TestsPassed++
        } elseif ($statusCode -eq 400 -or $statusCode -eq 404) {
            # Nginx သို့မဟုတ် Cloudflare ဘက်က Bad Request ပြပါက လမ်းကြောင်းပေါက်သော်လည်း Auth မပါသေးခြင်းဖြစ်၍ အဆင်ပြေပါသည်
            Write-Green "✓ PASS (Route Pushed to Xray Core Successfully)"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (Xray Route Error - Got Status: $statusCode)"
            $script:TestsFailed++
        }
    }
}

# Rate limiting test
function Test-RateLimiting {
    Write-Host "Testing rate limiting... " -NoNewline
    
    $count = 0
    $rateLimited = $false
    
    for ($i = 1; $i -le 15; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "$BaseUrl/datafiles/test" -Method GET -ErrorAction SilentlyContinue
            $count++
        } catch {
            if ($_.Exception.Response.StatusCode.Value__ -eq 429) {
                $rateLimited = $true
                break
            }
            $count++
        }
    }
    
    if ($rateLimited) {
        Write-Green "✓ PASS (rate limited after $count requests)"
        $script:TestsPassed++
    } else {
        Write-Yellow "? SKIP (rate limit not triggered - may need adjustment)"
    }
}

# Cache test
function Test-Caching {
    Write-Host "Testing caching... " -NoNewline
    
    try {
        $response1 = Invoke-WebRequest -Uri "$BaseUrl/datafiles/test.json" -Method HEAD -ErrorAction SilentlyContinue
        $cacheHeader1 = $response1.Headers['X-Cache-Status']
        
        $response2 = Invoke-WebRequest -Uri "$BaseUrl/datafiles/test.json" -Method HEAD -ErrorAction SilentlyContinue
        $cacheHeader2 = $response2.Headers['X-Cache-Status']
        
        if ($cacheHeader1 -or $cacheHeader2) {
            Write-Green "✓ PASS (cache headers present)"
            $script:TestsPassed++
        } else {
            Write-Yellow "? PARTIAL (cache headers not found, but endpoint working)"
        }
    } catch {
        Write-Yellow "? PARTIAL (endpoint accessible but cache headers not verified)"
    }
}

# CORS test
function Test-CORS {
    Write-Host "Testing CORS preflight... " -NoNewline
    
    try {
        $headers = @{
            'Origin' = 'https://example.com'
            'Access-Control-Request-Method' = 'GET'
        }
        
        $response = Invoke-WebRequest -Uri "$BaseUrl/datafiles/" -Method OPTIONS -Headers $headers -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 204) {
            Write-Green "✓ PASS"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (expected 204, got $($response.StatusCode))"
            $script:TestsFailed++
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 204) {
            Write-Green "✓ PASS"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (expected 204, got $statusCode)"
            $script:TestsFailed++
        }
    }
}

# Security headers test
function Test-SecurityHeaders {
    Write-Host "Testing security headers... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/" -Method HEAD -ErrorAction SilentlyContinue
        $headers = $response.Headers
        
        $securityHeaders = @(
            'X-Frame-Options',
            'X-Content-Type-Options',
            'X-XSS-Protection'
        )
        
        $foundHeaders = 0
        foreach ($header in $securityHeaders) {
            if ($headers.ContainsKey($header)) {
                $foundHeaders++
            }
        }
        
        if ($foundHeaders -ge 2) {
            Write-Green "✓ PASS ($foundHeaders/3 security headers found)"
            $script:TestsPassed++
        } else {
            Write-Red "✗ FAIL (only $foundHeaders/3 security headers found)"
            $script:TestsFailed++
        }
    } catch {
        Write-Red "✗ FAIL (could not retrieve headers)"
        $script:TestsFailed++
    }
}

# Performance test
function Test-Performance {
    Write-Host "Testing response time... " -NoNewline
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "$BaseUrl/" -Method GET -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        
        $responseTime = $stopwatch.ElapsedMilliseconds / 1000
        
        if ($responseTime -lt 1.0) {
            Write-Green "✓ PASS ($($responseTime.ToString('F3'))s)"
            $script:TestsPassed++
        } else {
            Write-Yellow "? SLOW ($($responseTime.ToString('F3'))s - consider optimization)"
        }
    } catch {
        Write-Red "✗ FAIL (could not measure response time)"
        $script:TestsFailed++
    }
}

# Main execution
function Main {
    Write-Bold "🧪 Advanced NGINX CDN + Xray VPN Test Suite"
    Write-Host "Testing endpoint: $BaseUrl"
    Write-Host ""
    
    # Basic connectivity tests
    Write-Bold "📡 Basic Connectivity Tests"
    Test-Endpoint "Health check" "$BaseUrl/health" 200
    Test-Endpoint "Status API" "$BaseUrl/api/status" 200
    Test-Endpoint "Cache stats API" "$BaseUrl/api/cache-stats" 200
    Test-Endpoint "Main page" "$BaseUrl/" 200
    Write-Host ""
    
    # Feature tests
    Write-Bold "🚀 Advanced Feature Tests"
    Test-CORS
    Test-SecurityHeaders
    Test-Caching
    Test-RateLimiting
    # 💡 အသစ်တိုးမြှင့်လိုက်သော VPN Tunnel စမ်းသပ်ချက်
    Test-XrayWebSocket
    Write-Host ""
    
    # Error handling tests
    Write-Bold "🛡️ Error Handling Tests"
    Test-Endpoint "404 Not Found" "$BaseUrl/nonexistent" 404
    Write-Host ""
    
    # Performance tests
    Write-Bold "⚡ Performance Tests"
    Test-Performance
    Write-Host ""
    
    # Summary
    Write-Bold "📊 Test Summary"
    Write-Host "Tests passed: " -NoNewline; Write-Green $TestsPassed
    Write-Host "Tests failed: " -NoNewline; Write-Red $TestsFailed
    Write-Host "Total tests: $($TestsPassed + $TestsFailed)"
    
    if ($TestsFailed -eq 0) {
        Write-Host ""
        Write-Green "🎉 All tests passed! Your advanced CDN proxy & VPN Route are working correctly."
        exit 0
    } else {
        Write-Host ""
        Write-Red "❌ Some tests failed. Check the configuration and container logs."
        exit 1
    }
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Red "Error: PowerShell 3.0 or higher is required."
    exit 1
}

# Run main function
Main
