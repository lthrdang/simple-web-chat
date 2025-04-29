param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$ScanPath = "."
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if npm is installed
$npmStatus = npm --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "npm is not installed. Please install Node.js and try again."
    exit 1
}

# Install security scanning tools
Write-Host "Installing security scanning tools..."
npm install -g npm-audit-fix
npm install -g snyk

# Run npm audit
Write-Host "Running npm audit..."
npm audit

# Run Snyk security scan
Write-Host "Running Snyk security scan..."
snyk test

# Check for sensitive data in code
Write-Host "Checking for sensitive data in code..."
$sensitivePatterns = @(
    "password",
    "secret",
    "key",
    "token",
    "api[_-]?key",
    "aws[_-]?key",
    "private[_-]?key",
    "ssh[_-]?key",
    "access[_-]?token",
    "auth[_-]?token",
    "jwt[_-]?secret",
    "mongodb[_-]?uri",
    "redis[_-]?url"
)

$sensitiveFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx", ".json", ".env", ".yaml", ".yml")
} | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = $sensitivePatterns | ForEach-Object {
        if ($content -match $_) {
            @{
                File = $_.FullName
                Pattern = $_
                Line = ($content -split "`n" | Select-String $_).LineNumber
            }
        }
    }
    $matches | Where-Object { $_ -ne $null }
}

if ($sensitiveFiles) {
    Write-Host "`nPotential sensitive data found:"
    $sensitiveFiles | ForEach-Object {
        Write-Host "File: $($_.File)"
        Write-Host "Pattern: $($_.Pattern)"
        Write-Host "Line: $($_.Line)"
        Write-Host "---"
    }
} else {
    Write-Host "No sensitive data found."
}

# Check for outdated dependencies
Write-Host "`nChecking for outdated dependencies..."
npm outdated

# Check for known vulnerabilities
Write-Host "`nChecking for known vulnerabilities..."
npm audit

# Generate security report
$reportPath = "./security-reports"
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFile = "$reportPath/security-report-$Environment-$timestamp.txt"

@"
Security Scan Report
Environment: $Environment
Date: $(Get-Date)

1. NPM Audit Results:
$(npm audit --json | ConvertFrom-Json | ConvertTo-Json -Depth 10)

2. Snyk Scan Results:
$(snyk test --json | ConvertFrom-Json | ConvertTo-Json -Depth 10)

3. Sensitive Data Check:
$($sensitiveFiles | ConvertTo-Json -Depth 10)

4. Outdated Dependencies:
$(npm outdated --json | ConvertFrom-Json | ConvertTo-Json -Depth 10)
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`nSecurity scan completed!"
Write-Host "Report saved to: $reportFile" 