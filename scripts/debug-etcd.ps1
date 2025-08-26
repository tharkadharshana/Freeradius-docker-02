#!/usr/bin/env pwsh

# Debug script for ETCD

$ETCD_HOST = "localhost"
$ETCD_PORT = "2379"
$ETCD_BASE_URL = "http://${ETCD_HOST}:${ETCD_PORT}"

Write-Host "Testing with a single file..." -ForegroundColor Yellow

# Test with radiusd.conf
$filePath = "freeradius-docker_reference_only_previous_working_production/configs/radius1/radiusd.conf"

if (Test-Path $filePath) {
    Write-Host "File exists: $filePath" -ForegroundColor Green
    
    $content = Get-Content $filePath -Raw -Encoding UTF8
    Write-Host "Content length: $($content.Length)" -ForegroundColor Cyan
    
    $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    Write-Host "Base64 length: $($base64Content.Length)" -ForegroundColor Cyan
    
    # Test the API call
    $body = @{
        key = "/freeradius/test/radiusd.conf"
        value = $base64Content
    } | ConvertTo-Json
    
    Write-Host "Request body: $body" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "$ETCD_BASE_URL/v3/kv/put" -Method POST -ContentType "application/json" -Body $body
        
        Write-Host "✅ Success!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
        
        # Now try to get it back
        $getBody = @{
            key = "/freeradius/test/radiusd.conf"
        } | ConvertTo-Json
        
        $getResponse = Invoke-RestMethod -Uri "$ETCD_BASE_URL/v3/kv/range" -Method POST -ContentType "application/json" -Body $getBody
        
        Write-Host "✅ Retrieved successfully!" -ForegroundColor Green
        Write-Host "Retrieved: $($getResponse | ConvertTo-Json)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Full error: $($_.Exception)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ File not found: $filePath" -ForegroundColor Red
}
