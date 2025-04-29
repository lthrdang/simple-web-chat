param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$MongoUri,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./backups",
    
    [Parameter(Mandatory=$false)]
    [switch]$Restore
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if mongodump is installed
$mongodumpStatus = mongodump --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "MongoDB Tools are not installed. Please install them and try again."
    exit 1
}

# Create backup directory if it doesn't exist
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath
    Write-Host "Created backup directory: $BackupPath"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$backupDir = "$BackupPath/$Environment-$timestamp"

if (-not $Restore) {
    # Create backup
    Write-Host "Creating backup..."
    mongodump --uri $MongoUri --out $backupDir

    if ($LASTEXITCODE -eq 0) {
        # Compress backup
        Write-Host "Compressing backup..."
        Compress-Archive -Path $backupDir -DestinationPath "$backupDir.zip"
        Remove-Item -Path $backupDir -Recurse -Force

        Write-Host "Backup completed successfully!"
        Write-Host "Backup file: $backupDir.zip"
    } else {
        Write-Host "Backup failed!"
        exit 1
    }
} else {
    # Restore from backup
    if (-not (Test-Path $BackupPath)) {
        Write-Host "No backup found at: $BackupPath"
        exit 1
    }

    # Get latest backup
    $latestBackup = Get-ChildItem -Path $BackupPath -Filter "$Environment-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $latestBackup) {
        Write-Host "No backup found for environment: $Environment"
        exit 1
    }

    # Extract backup
    Write-Host "Extracting backup..."
    $extractPath = "$BackupPath/temp"
    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
    Expand-Archive -Path $latestBackup.FullName -DestinationPath $extractPath

    # Restore backup
    Write-Host "Restoring backup..."
    mongorestore --uri $MongoUri --dir $extractPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Restore completed successfully!"
    } else {
        Write-Host "Restore failed!"
        exit 1
    }

    # Clean up
    Remove-Item -Path $extractPath -Recurse -Force
}

# Clean up old backups (keep last 7 days)
$cutoffDate = (Get-Date).AddDays(-7)
Get-ChildItem -Path $BackupPath -Filter "$Environment-*.zip" | Where-Object { $_.LastWriteTime -lt $cutoffDate } | Remove-Item -Force 