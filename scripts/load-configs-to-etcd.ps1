#!/usr/bin/env pwsh

# FreeRADIUS Configuration Loader for Windows
# This script loads all FreeRADIUS configurations into ETCD

$ETCD_HOST = "localhost"
$ETCD_PORT = "2379"
$ETCD_BASE_URL = "http://${ETCD_HOST}:${ETCD_PORT}"
$REFERENCE_DIR = "freeradius-docker_reference_only_previous_working_production/configs"

Write-Host "========================================" -ForegroundColor Green
Write-Host "FreeRADIUS Configuration Loader for ETCD" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host

# Function to encode content to base64
function Convert-ToBase64 {
    param([string]$Content)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    return [Convert]::ToBase64String($bytes)
}

# Function to load a single configuration file into ETCD
function Load-ConfigToEtcd {
    param(
        [string]$Key,
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        try {
            $content = Get-Content $FilePath -Raw -Encoding UTF8
            if ($content) {
                $base64Content = Convert-ToBase64 $content
                
                $body = @{
                    key = $Key
                    value = $base64Content
                } | ConvertTo-Json
                
                Write-Host "Loading: $Key" -ForegroundColor Yellow
                
                $response = Invoke-RestMethod -Uri "$ETCD_BASE_URL/v3/kv/put" -Method POST -ContentType "application/json" -Body $body
                
                if ($response.header.revision -gt 0) {
                    Write-Host "✅ Loaded: $Key" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "❌ Failed to load: $Key" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "⚠️  Empty file: $FilePath" -ForegroundColor Yellow
                return $false
            }
        }
        catch {
            Write-Host "❌ Error loading $Key`: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️  File not found: $FilePath" -ForegroundColor Yellow
        return $false
    }
}

# Function to load configurations for a specific service
function Load-ServiceConfigs {
    param([string]$ServiceName)
    
    Write-Host "Loading configurations for $ServiceName..." -ForegroundColor Cyan
    
    $serviceDir = Join-Path $REFERENCE_DIR $ServiceName
    
    if (-not (Test-Path $serviceDir)) {
        Write-Host "⚠️  Service directory not found: $serviceDir" -ForegroundColor Yellow
        return
    }
    
    # Load main config files
    $mainConfigs = @("radiusd.conf", "clients.conf", "sql.conf", "experimental.conf", "templates.conf", "trigger.conf")
    foreach ($config in $mainConfigs) {
        $filePath = Join-Path $serviceDir $config
        $etcdKey = "/freeradius/$ServiceName/$config"
        Load-ConfigToEtcd -Key $etcdKey -FilePath $filePath
    }
    
    # Load mods-available
    $modsDir = Join-Path $serviceDir "mods-available"
    if (Test-Path $modsDir) {
        Get-ChildItem $modsDir -File | ForEach-Object {
            $etcdKey = "/freeradius/$ServiceName/mods-available/$($_.Name)"
            Load-ConfigToEtcd -Key $etcdKey -FilePath $_.FullName
        }
    }
    
    # Load mods-config (simplified - just main files)
    $modsConfigDir = Join-Path $serviceDir "mods-config"
    if (Test-Path $modsConfigDir) {
        Get-ChildItem $modsConfigDir -File | ForEach-Object {
            $etcdKey = "/freeradius/$ServiceName/mods-config/$($_.Name)"
            Load-ConfigToEtcd -Key $etcdKey -FilePath $_.FullName
        }
    }
    
    # Load policy.d
    $policyDir = Join-Path $serviceDir "policy.d"
    if (Test-Path $policyDir) {
        Get-ChildItem $policyDir -File | ForEach-Object {
            $etcdKey = "/freeradius/$ServiceName/policy.d/$($_.Name)"
            Load-ConfigToEtcd -Key $etcdKey -FilePath $_.FullName
        }
    }
    
    # Load sites-available
    $sitesDir = Join-Path $serviceDir "sites-available"
    if (Test-Path $sitesDir) {
        Get-ChildItem $sitesDir -File | ForEach-Object {
            $etcdKey = "/freeradius/$ServiceName/sites-available/$($_.Name)"
            Load-ConfigToEtcd -Key $etcdKey -FilePath $_.FullName
        }
    }
    
    # Load dict
    $dictDir = Join-Path $serviceDir "dict"
    if (Test-Path $dictDir) {
        Get-ChildItem $dictDir -File | ForEach-Object {
            $etcdKey = "/freeradius/$ServiceName/dict/$($_.Name)"
            Load-ConfigToEtcd -Key $etcdKey -FilePath $_.FullName
        }
    }
    
    Write-Host "Completed loading configurations for $ServiceName" -ForegroundColor Green
}

# Main execution
Write-Host "Starting configuration loading process..." -ForegroundColor Yellow
Write-Host "ETCD URL: $ETCD_BASE_URL" -ForegroundColor Yellow
Write-Host "Reference Directory: $REFERENCE_DIR" -ForegroundColor Yellow
Write-Host

# Check if ETCD is accessible
try {
    $healthResponse = Invoke-RestMethod -Uri "$ETCD_BASE_URL/health" -Method GET
    Write-Host "✅ ETCD is accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to ETCD at $ETCD_BASE_URL" -ForegroundColor Red
    Write-Host "Make sure ETCD container is running" -ForegroundColor Red
    exit 1
}

# Check if reference directory exists
if (-not (Test-Path $REFERENCE_DIR)) {
    Write-Host "❌ Reference directory not found: $REFERENCE_DIR" -ForegroundColor Red
    exit 1
}

Write-Host "Loading configurations..." -ForegroundColor Yellow

# Load radius1 configs
Load-ServiceConfigs "radius1"

# Load radius2 configs
Load-ServiceConfigs "radius2"

# Load loadbalancer configs
Load-ServiceConfigs "loadbalancer"

Write-Host
Write-Host "Configuration loading completed!" -ForegroundColor Green
Write-Host
Write-Host "To verify, check ETCD contents:" -ForegroundColor Yellow
Write-Host "docker exec freeradius-etcd etcdctl get --prefix /freeradius" -ForegroundColor Cyan
