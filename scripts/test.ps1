param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$Unit,
    
    [Parameter(Mandatory=$false)]
    [switch]$Integration,
    
    [Parameter(Mandatory=$false)]
    [switch]$E2E,
    
    [Parameter(Mandatory=$false)]
    [switch]$Coverage,
    
    [Parameter(Mandatory=$false)]
    [switch]$Watch
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

# Create test report directory
$reportPath = "./test-reports"
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
    Write-Host "Created test report directory: $reportPath"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFile = "$reportPath/test-report-$Environment-$timestamp.txt"

# Function to run tests
function Run-Tests {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type
    )
    
    Write-Host "Running $Type tests for $Name..."
    
    # Change to directory
    Push-Location $Path
    
    # Build test command
    $testCmd = "npm test"
    
    if ($Coverage) {
        $testCmd += " -- --coverage"
    }
    
    if ($Watch) {
        $testCmd += " -- --watch"
    }
    
    # Run tests
    $testOutput = Invoke-Expression $testCmd
    $testResults = @{
        Name = $Name
        Type = $Type
        Output = $testOutput
        Success = $LASTEXITCODE -eq 0
    }
    
    # Restore directory
    Pop-Location
    
    return $testResults
}

# Run tests based on parameters
$testResults = @()

if ($Unit) {
    $testResults += Run-Tests -Path "./frontend" -Name "Frontend" -Type "Unit"
    $testResults += Run-Tests -Path "./backend" -Name "Backend" -Type "Unit"
}

if ($Integration) {
    $testResults += Run-Tests -Path "./frontend" -Name "Frontend" -Type "Integration"
    $testResults += Run-Tests -Path "./backend" -Name "Backend" -Type "Integration"
}

if ($E2E) {
    $testResults += Run-Tests -Path "./frontend" -Name "Frontend" -Type "E2E"
    $testResults += Run-Tests -Path "./backend" -Name "Backend" -Type "E2E"
}

# Generate test report
@"
Test Report
Environment: $Environment
Date: $(Get-Date)

Test Results:
$($testResults | ForEach-Object {
    @"
$($_.Name) - $($_.Type) Tests:
Success: $($_.Success)
Output:
$($_.Output)
"@
})

Summary:
$($testResults | Group-Object -Property Type | ForEach-Object {
    $type = $_.Name
    $success = ($_.Group | Where-Object { $_.Success }).Count
    $total = $_.Group.Count
    @"
$type Tests: $success/$total passed
"@
})

Recommendations:
1. Fix failing tests
2. Add more test coverage
3. Write unit tests for new features
4. Add integration tests
5. Add end-to-end tests
6. Regular test maintenance
7. Test documentation
8. Performance testing
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`nTest execution completed!"
Write-Host "Report saved to: $reportFile"

# Print summary
Write-Host "`nSummary:"
$testResults | Group-Object -Property Type | ForEach-Object {
    $type = $_.Name
    $success = ($_.Group | Where-Object { $_.Success }).Count
    $total = $_.Group.Count
    Write-Host "$type Tests: $success/$total passed"
} 