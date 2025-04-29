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

# Create compliance report directory
$reportPath = "./compliance-reports"
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
    Write-Host "Created compliance report directory: $reportPath"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFile = "$reportPath/compliance-report-$Environment-$timestamp.txt"

# GDPR Compliance Checks
Write-Host "Running GDPR compliance checks..."

$gdprChecks = @{
    "Data Minimization" = @{
        Description = "Only necessary personal data is collected"
        Status = "Not Checked"
        Findings = @()
    }
    "Consent Management" = @{
        Description = "User consent is properly managed"
        Status = "Not Checked"
        Findings = @()
    }
    "Data Retention" = @{
        Description = "Data retention policies are implemented"
        Status = "Not Checked"
        Findings = @()
    }
    "Data Portability" = @{
        Description = "Users can export their data"
        Status = "Not Checked"
        Findings = @()
    }
    "Right to be Forgotten" = @{
        Description = "Users can request data deletion"
        Status = "Not Checked"
        Findings = @()
    }
}

# Check for data minimization
$personalDataPatterns = @(
    "email",
    "phone",
    "address",
    "name",
    "birth",
    "ssn",
    "credit[_-]?card",
    "password"
)

$personalDataFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx", ".json", ".env", ".yaml", ".yml")
} | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = $personalDataPatterns | ForEach-Object {
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

if ($personalDataFiles) {
    $gdprChecks["Data Minimization"].Status = "Warning"
    $gdprChecks["Data Minimization"].Findings = $personalDataFiles
} else {
    $gdprChecks["Data Minimization"].Status = "Pass"
}

# Check for consent management
$consentFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx")
} | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "consent|permission|authorize|agree"
}

if ($consentFiles) {
    $gdprChecks["Consent Management"].Status = "Pass"
} else {
    $gdprChecks["Consent Management"].Status = "Warning"
    $gdprChecks["Consent Management"].Findings = @("No consent management found")
}

# Check for data retention
$retentionFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx")
} | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "retention|expire|delete|remove"
}

if ($retentionFiles) {
    $gdprChecks["Data Retention"].Status = "Pass"
} else {
    $gdprChecks["Data Retention"].Status = "Warning"
    $gdprChecks["Data Retention"].Findings = @("No data retention policies found")
}

# Check for data portability
$portabilityFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx")
} | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "export|download|portability"
}

if ($portabilityFiles) {
    $gdprChecks["Data Portability"].Status = "Pass"
} else {
    $gdprChecks["Data Portability"].Status = "Warning"
    $gdprChecks["Data Portability"].Findings = @("No data portability features found")
}

# Check for right to be forgotten
$deletionFiles = Get-ChildItem -Path $ScanPath -Recurse -File | Where-Object {
    $_.Extension -in @(".js", ".ts", ".jsx", ".tsx")
} | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "delete[_-]?account|remove[_-]?account|forget"
}

if ($deletionFiles) {
    $gdprChecks["Right to be Forgotten"].Status = "Pass"
} else {
    $gdprChecks["Right to be Forgotten"].Status = "Warning"
    $gdprChecks["Right to be Forgotten"].Findings = @("No account deletion features found")
}

# Generate compliance report
@"
Compliance Report
Environment: $Environment
Date: $(Get-Date)

GDPR Compliance Checks:
$($gdprChecks.GetEnumerator() | ForEach-Object {
    @"
$($_.Key):
Description: $($_.Value.Description)
Status: $($_.Value.Status)
Findings:
$($_.Value.Findings | ForEach-Object { "- $_" })
"@
})

Recommendations:
1. Implement proper consent management if not present
2. Add data retention policies
3. Enable data portability features
4. Add account deletion functionality
5. Review and minimize personal data collection
6. Document all data processing activities
7. Implement data encryption at rest and in transit
8. Regular security audits and updates
"@ | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`nCompliance check completed!"
Write-Host "Report saved to: $reportFile" 