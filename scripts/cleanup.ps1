param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$All,
    
    [Parameter(Mandatory=$false)]
    [switch]$Docker,
    
    [Parameter(Mandatory=$false)]
    [switch]$Node,
    
    [Parameter(Mandatory=$false)]
    [switch]$Logs,
    
    [Parameter(Mandatory=$false)]
    [switch]$Reports,
    
    [Parameter(Mandatory=$false)]
    [switch]$Backups,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Function to confirm action
function Confirm-Action {
    param(
        [string]$Message
    )
    
    if (-not $Force) {
        $confirmation = Read-Host "$Message (y/n)"
        return $confirmation -eq "y"
    }
    
    return $true
}

# Clean Docker resources
if ($All -or $Docker) {
    if (Confirm-Action "Do you want to clean Docker resources?") {
        Write-Host "Cleaning Docker resources..."
        
        # Stop and remove containers
        docker-compose down
        
        # Remove unused images
        docker image prune -f
        
        # Remove unused volumes
        docker volume prune -f
        
        # Remove unused networks
        docker network prune -f
        
        Write-Host "Docker cleanup completed"
    }
}

# Clean Node.js resources
if ($All -or $Node) {
    if (Confirm-Action "Do you want to clean Node.js resources?") {
        Write-Host "Cleaning Node.js resources..."
        
        # Clean frontend
        Set-Location ./frontend
        Remove-Item -Path "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
        npm cache clean --force
        Set-Location ..
        
        # Clean backend
        Set-Location ./backend
        Remove-Item -Path "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "dist" -Recurse -Force -ErrorAction SilentlyContinue
        npm cache clean --force
        Set-Location ..
        
        Write-Host "Node.js cleanup completed"
    }
}

# Clean logs
if ($All -or $Logs) {
    if (Confirm-Action "Do you want to clean logs?") {
        Write-Host "Cleaning logs..."
        
        # Clean log files
        Get-ChildItem -Path "./logs" -File | Remove-Item -Force
        
        Write-Host "Log cleanup completed"
    }
}

# Clean reports
if ($All -or $Reports) {
    if (Confirm-Action "Do you want to clean reports?") {
        Write-Host "Cleaning reports..."
        
        # Clean report directories
        $reportDirs = @(
            "./quality-reports",
            "./dependency-reports",
            "./compliance-reports",
            "./performance-reports",
            "./security-reports",
            "./test-reports"
        )
        
        foreach ($dir in $reportDirs) {
            if (Test-Path $dir) {
                Get-ChildItem -Path $dir -File | Remove-Item -Force
            }
        }
        
        Write-Host "Report cleanup completed"
    }
}

# Clean backups
if ($All -or $Backups) {
    if (Confirm-Action "Do you want to clean backups?") {
        Write-Host "Cleaning backups..."
        
        # Clean backup files
        Get-ChildItem -Path "./backups" -File | Remove-Item -Force
        
        Write-Host "Backup cleanup completed"
    }
}

# Clean temporary files
if ($All) {
    if (Confirm-Action "Do you want to clean temporary files?") {
        Write-Host "Cleaning temporary files..."
        
        # Clean temporary files
        Get-ChildItem -Path "." -Include "*.tmp", "*.temp", "*.log", "*.bak" -Recurse | Remove-Item -Force
        
        Write-Host "Temporary file cleanup completed"
    }
}

Write-Host "`nCleanup completed!"
Write-Host "Next steps:"
Write-Host "1. Run setup.ps1 to reinstall dependencies"
Write-Host "2. Start services with docker-compose up -d"
Write-Host "3. Run development servers with npm run dev" 