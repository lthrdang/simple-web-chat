param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$ScanPath = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$Fix
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

# Create quality report directory
$reportPath = "./quality-reports"
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
    Write-Host "Created quality report directory: $reportPath"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFile = "$reportPath/quality-report-$Environment-$timestamp.txt"

# Function to run ESLint
function Run-ESLint {
    param(
        [string]$Path,
        [string]$Name
    )
    
    Write-Host "Running ESLint on $Name..."
    
    # Change to directory
    Push-Location $Path
    
    if ($Fix) {
        # Fix issues automatically
        Write-Host "Fixing issues..."
        npx eslint . --fix
    }
    
    # Run ESLint
    $lintOutput = npx eslint . --format json
    $lintResults = $lintOutput | ConvertFrom-Json
    
    # Restore directory
    Pop-Location
    
    return $lintResults
}

# Function to run TypeScript compiler
function Run-TypeScript {
    param(
        [string]$Path,
        [string]$Name
    )
    
    Write-Host "Running TypeScript compiler on $Name..."
    
    # Change to directory
    Push-Location $Path
    
    # Run TypeScript compiler
    $tscOutput = npx tsc --noEmit
    $tscResults = @{
        Success = $LASTEXITCODE -eq 0
        Output = $tscOutput
    }
    
    # Restore directory
    Pop-Location
    
    return $tscResults
}

# Function to check code coverage
function Get-CodeCoverage {
    param(
        [string]$Path,
        [string]$Name
    )
    
    Write-Host "Checking code coverage for $Name..."
    
    # Change to directory
    Push-Location $Path
    
    # Run tests with coverage
    $coverageOutput = npm test -- --coverage
    $coverageResults = @{
        Output = $coverageOutput
    }
    
    # Restore directory
    Pop-Location
    
    return $coverageResults
}

# Run quality checks
$frontendLint = Run-ESLint -Path "./frontend" -Name "Frontend"
$backendLint = Run-ESLint -Path "./backend" -Name "Backend"

$frontendTypeScript = Run-TypeScript -Path "./frontend" -Name "Frontend"
$backendTypeScript = Run-TypeScript -Path "./backend" -Name "Backend"

$frontendCoverage = Get-CodeCoverage -Path "./frontend" -Name "Frontend"
$backendCoverage = Get-CodeCoverage -Path "./backend" -Name "Backend"

# Generate quality report
@"
Code Quality Report
Environment: $Environment
Date: $(Get-Date)

Frontend Quality Checks:
Path: ./frontend

ESLint Results:
$($frontendLint | ConvertTo-Json -Depth 10)

TypeScript Results:
Success: $($frontendTypeScript.Success)
Output:
$($frontendTypeScript.Output)

Code Coverage:
$($frontendCoverage.Output)

Backend Quality Checks:
Path: ./backend

ESLint Results:
$($backendLint | ConvertTo-Json -Depth 10)

TypeScript Results:
Success: $($backendTypeScript.Success)
Output:
$($backendTypeScript.Output)

Code Coverage:
$($backendCoverage.Output)

Recommendations:
1. Fix ESLint errors and warnings
2. Address TypeScript compilation issues
3. Improve code coverage
4. Follow coding standards
5. Use consistent formatting
6. Add proper documentation
7. Write unit tests
8. Perform code reviews
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`nCode quality check completed!"
Write-Host "Report saved to: $reportFile"

# Print summary
Write-Host "`nSummary:"
Write-Host "Frontend:"
Write-Host "- ESLint Errors: $($frontendLint.errorCount)"
Write-Host "- ESLint Warnings: $($frontendLint.warningCount)"
Write-Host "- TypeScript Success: $($frontendTypeScript.Success)"

Write-Host "`nBackend:"
Write-Host "- ESLint Errors: $($backendLint.errorCount)"
Write-Host "- ESLint Warnings: $($backendLint.warningCount)"
Write-Host "- TypeScript Success: $($backendTypeScript.Success)" 