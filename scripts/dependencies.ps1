param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$Update,
    
    [Parameter(Mandatory=$false)]
    [switch]$Audit,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
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

# Create dependency report directory
$reportPath = "./dependency-reports"
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
    Write-Host "Created dependency report directory: $reportPath"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFile = "$reportPath/dependency-report-$Environment-$timestamp.txt"

# Function to process a package.json file
function Process-PackageJson {
    param(
        [string]$Path,
        [string]$Name
    )
    
    Write-Host "Processing $Name dependencies..."
    
    # Change to directory
    Push-Location $Path
    
    if ($Update) {
        # Update dependencies
        Write-Host "Updating dependencies..."
        npm update
        npm audit fix
    }
    
    if ($Audit) {
        # Run security audit
        Write-Host "Running security audit..."
        npm audit
    }
    
    if ($Clean) {
        # Clean node_modules
        Write-Host "Cleaning node_modules..."
        Remove-Item -Path "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        npm cache clean --force
    }
    
    # Get dependency information
    $dependencies = @{
        Name = $Name
        Path = $Path
        Dependencies = (npm list --json | ConvertFrom-Json).dependencies
        Outdated = npm outdated --json | ConvertFrom-Json
        Vulnerabilities = npm audit --json | ConvertFrom-Json
    }
    
    # Restore directory
    Pop-Location
    
    return $dependencies
}

# Process frontend dependencies
$frontendDeps = Process-PackageJson -Path "./frontend" -Name "Frontend"

# Process backend dependencies
$backendDeps = Process-PackageJson -Path "./backend" -Name "Backend"

# Generate dependency report
@"
Dependency Management Report
Environment: $Environment
Date: $(Get-Date)

Frontend Dependencies:
Path: $($frontendDeps.Path)

Dependencies:
$($frontendDeps.Dependencies | ConvertTo-Json -Depth 10)

Outdated Packages:
$($frontendDeps.Outdated | ConvertTo-Json -Depth 10)

Vulnerabilities:
$($frontendDeps.Vulnerabilities | ConvertTo-Json -Depth 10)

Backend Dependencies:
Path: $($backendDeps.Path)

Dependencies:
$($backendDeps.Dependencies | ConvertTo-Json -Depth 10)

Outdated Packages:
$($backendDeps.Outdated | ConvertTo-Json -Depth 10)

Vulnerabilities:
$($backendDeps.Vulnerabilities | ConvertTo-Json -Depth 10)

Recommendations:
1. Update outdated packages
2. Fix security vulnerabilities
3. Remove unused dependencies
4. Keep dependencies up to date
5. Use exact versions for critical packages
6. Regular security audits
7. Document dependency changes
8. Test after updates
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`nDependency management completed!"
Write-Host "Report saved to: $reportFile"

# Print summary
Write-Host "`nSummary:"
Write-Host "Frontend:"
Write-Host "- Dependencies: $($frontendDeps.Dependencies.Count)"
Write-Host "- Outdated: $($frontendDeps.Outdated.Count)"
Write-Host "- Vulnerabilities: $($frontendDeps.Vulnerabilities.vulnerabilities.Count)"

Write-Host "`nBackend:"
Write-Host "- Dependencies: $($backendDeps.Dependencies.Count)"
Write-Host "- Outdated: $($backendDeps.Outdated.Count)"
Write-Host "- Vulnerabilities: $($backendDeps.Vulnerabilities.vulnerabilities.Count)" 