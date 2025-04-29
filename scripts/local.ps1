param(
    [Parameter(Mandatory=$false)]
    [switch]$Build,
    
    [Parameter(Mandatory=$false)]
    [switch]$Start,
    
    [Parameter(Mandatory=$false)]
    [switch]$Stop,
    
    [Parameter(Mandatory=$false)]
    [switch]$Restart,
    
    [Parameter(Mandatory=$false)]
    [switch]$Logs,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

# Check if Docker is running
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker and try again."
    exit 1
}

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..."
    @"
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# JWT
JWT_SECRET=your_jwt_secret
"@ | Out-File -FilePath .env -Encoding UTF8
    Write-Host "Please update the .env file with your actual credentials."
}

# Function to build services
function Build-Services {
    Write-Host "Building services..."
    docker-compose build
}

# Function to start services
function Start-Services {
    Write-Host "Starting services..."
    docker-compose up -d
}

# Function to stop services
function Stop-Services {
    Write-Host "Stopping services..."
    docker-compose down
}

# Function to restart services
function Restart-Services {
    Write-Host "Restarting services..."
    docker-compose restart
}

# Function to show logs
function Show-Logs {
    Write-Host "Showing logs..."
    docker-compose logs -f
}

# Function to clean up
function Clean-Up {
    Write-Host "Cleaning up..."
    docker-compose down -v
    Remove-Item -Path .env -Force -ErrorAction SilentlyContinue
}

# Execute requested operations
if ($Build) {
    Build-Services
}

if ($Start) {
    Start-Services
}

if ($Stop) {
    Stop-Services
}

if ($Restart) {
    Restart-Services
}

if ($Logs) {
    Show-Logs
}

if ($Clean) {
    Clean-Up
}

# If no parameters provided, show help
if (-not ($Build -or $Start -or $Stop -or $Restart -or $Logs -or $Clean)) {
    Write-Host "`nUsage:"
    Write-Host "  .\scripts\local.ps1 -Build    # Build services"
    Write-Host "  .\scripts\local.ps1 -Start    # Start services"
    Write-Host "  .\scripts\local.ps1 -Stop     # Stop services"
    Write-Host "  .\scripts\local.ps1 -Restart  # Restart services"
    Write-Host "  .\scripts\local.ps1 -Logs     # Show logs"
    Write-Host "  .\scripts\local.ps1 -Clean    # Clean up everything"
} 