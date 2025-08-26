# Load FreeRADIUS configurations into ETCD
# This script loads all configuration files from the reference directory into ETCD

$ETCD_ENDPOINT = "http://localhost:2379"
$REFERENCE_DIR = "freeradius-docker_reference_only_previous_working_production\configs"

Write-Host "Loading FreeRADIUS configurations into ETCD at $ETCD_ENDPOINT" -ForegroundColor Green

# Function to load config file into ETCD
function Load-ConfigToEtcd {
    param(
        [string]$Service,
        [string]$ConfigFile
    )
    
    $etcdKey = "/freeradius/$Service/$ConfigFile"
    $configPath = "$REFERENCE_DIR\$Service\$ConfigFile"
    
    if (Test-Path $configPath) {
        Write-Host "Loading $etcdKey" -ForegroundColor Yellow
        
        try {
            # Read file content and encode it properly for ETCD
            $content = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($configPath))
            $keyBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($etcdKey))
            
            $body = @{
                key = $keyBase64
                value = $content
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri "$ETCD_ENDPOINT/v3/kv/put" -Method PUT -Body $body -ContentType "application/json"
            
            Write-Host "✅ Loaded $etcdKey" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to load $etcdKey : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "⚠️  File not found: $configPath" -ForegroundColor Yellow
    }
}

# Function to load all configs for a service
function Load-ServiceConfigs {
    param([string]$Service)
    
    Write-Host "Loading configurations for $Service..." -ForegroundColor Cyan
    
    # Load main config files
    Load-ConfigToEtcd $Service "radiusd.conf"
    Load-ConfigToEtcd $Service "clients.conf"
    Load-ConfigToEtcd $Service "sql.conf"
    Load-ConfigToEtcd $Service "experimental.conf"
    Load-ConfigToEtcd $Service "templates.conf"
    Load-ConfigToEtcd $Service "trigger.conf"
    
    # Load mods-available files
    $modsDir = "$REFERENCE_DIR\$Service\mods-available"
    if (Test-Path $modsDir) {
        Get-ChildItem $modsDir -File | ForEach-Object {
            Load-ConfigToEtcd $Service "mods-available\$($_.Name)"
        }
    }
    
    # Load mods-config files
    $modsConfigDir = "$REFERENCE_DIR\$Service\mods-config"
    if (Test-Path $modsConfigDir) {
        Get-ChildItem $modsConfigDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($REFERENCE_DIR.Length + $Service.Length + 2)
            Load-ConfigToEtcd $Service "mods-config\$relativePath"
        }
    }
    
    # Load policy.d files
    $policyDir = "$REFERENCE_DIR\$Service\policy.d"
    if (Test-Path $policyDir) {
        Get-ChildItem $policyDir -File | ForEach-Object {
            Load-ConfigToEtcd $Service "policy.d\$($_.Name)"
        }
    }
    
    # Load sites-available files
    $sitesDir = "$REFERENCE_DIR\$Service\sites-available"
    if (Test-Path $sitesDir) {
        Get-ChildItem $sitesDir -File | ForEach-Object {
            Load-ConfigToEtcd $Service "sites-available\$($_.Name)"
        }
    }
    
    # Load dictionary files
    $dictDir = "$REFERENCE_DIR\$Service\dict"
    if (Test-Path $dictDir) {
        Get-ChildItem $dictDir -File | ForEach-Object {
            Load-ConfigToEtcd $Service "dict\$($_.Name)"
        }
    }
    
    Write-Host "Completed loading configurations for $Service" -ForegroundColor Green
}

# Load configurations for all services
Write-Host "Starting configuration loading process..." -ForegroundColor Green

# Load radius1 configs
Load-ServiceConfigs "radius1"

# Load radius2 configs (use radius1 as template for now)
Load-ServiceConfigs "radius2"

# Load radius3 configs (use radius1 as template for now)
Load-ServiceConfigs "radius3"

# Load loadbalancer configs (use radius1 as template for now)
Load-ServiceConfigs "loadbalancer"

# Load loadbalancer2 configs (use radius1 as template for now)
Load-ServiceConfigs "loadbalancer2"

Write-Host "Configuration loading completed!" -ForegroundColor Green
Write-Host ""
Write-Host "To verify, check ETCD contents:" -ForegroundColor Cyan
Write-Host "curl -s '$ETCD_ENDPOINT/v3/kv/range' -H 'Content-Type: application/json' -d '{\"key\": \"L2ZyZWVyYWRpdXMv\", \"range_end\": \"L2ZyZWVyYWRpdXMvMA==\"}'"
