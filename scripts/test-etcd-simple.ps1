#!/usr/bin/env pwsh

# Simple ETCD test script

$ETCD_HOST = "localhost"
$ETCD_PORT = "2379"
$ETCD_BASE_URL = "http://${ETCD_HOST}:${ETCD_PORT}"

Write-Host "Testing ETCD connectivity..." -ForegroundColor Yellow
Write-Host "ETCD URL: $ETCD_BASE_URL" -ForegroundColor Yellow

# Test 1: Check ETCD health
try {
    $healthResponse = Invoke-RestMethod -Uri "$ETCD_BASE_URL/health" -Method GET
    Write-Host "✅ ETCD health check passed" -ForegroundColor Green
    Write-Host "Response: $($healthResponse | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ ETCD health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Try to put a simple key
try {
    $body = @{
        key = "L3Rlc3QtcHV0"
        value = "aGVsbG8td29ybGQ="
    } | ConvertTo-Json
    
    Write-Host "Testing PUT request..." -ForegroundColor Yellow
    Write-Host "Body: $body" -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri "$ETCD_BASE_URL/v3/kv/put" -Method POST -ContentType "application/json" -Body $body
    
    Write-Host "✅ PUT request successful" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ PUT request failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.Exception)" -ForegroundColor Red
}

# Test 3: Try to get the key back
try {
    $body = @{
        key = "L3Rlc3QtcHV0"
    } | ConvertTo-Json
    
    Write-Host "Testing GET request..." -ForegroundColor Yellow
    Write-Host "Body: $body" -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri "$ETCD_BASE_URL/v3/kv/range" -Method POST -ContentType "application/json" -Body $body
    
    Write-Host "✅ GET request successful" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ GET request failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.Exception)" -ForegroundColor Red
}
