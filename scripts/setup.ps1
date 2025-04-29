param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if Node.js is installed
$nodeStatus = node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Node.js is not installed. Please install Node.js and try again."
    exit 1
}

# Check if Docker is installed
$dockerStatus = docker --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not installed. Please install Docker and try again."
    exit 1
}

# Check if Docker Compose is installed
$composeStatus = docker-compose --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
}

# Create necessary directories
$directories = @(
    "./frontend",
    "./backend",
    "./scripts",
    "./docs",
    "./logs",
    "./backups",
    "./monitoring",
    "./quality-reports",
    "./dependency-reports",
    "./compliance-reports",
    "./performance-reports",
    "./security-reports"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir
        Write-Host "Created directory: $dir"
    }
}

# Create environment-specific configuration
$configPath = "./config"
if (-not (Test-Path $configPath)) {
    New-Item -ItemType Directory -Path $configPath
    Write-Host "Created config directory"
}

# Create environment configuration file
$envConfig = @{
    Environment = $Environment
    Frontend = @{
        Port = 3000
        Host = "localhost"
        ApiUrl = "http://localhost:5000"
        WsUrl = "ws://localhost:5000"
    }
    Backend = @{
        Port = 5000
        Host = "localhost"
        MongoUri = "mongodb://localhost:27017/chat"
        RedisUrl = "redis://localhost:6379"
    }
    Monitoring = @{
        Enabled = $true
        LogLevel = "info"
        MetricsPort = 9090
    }
    Security = @{
        JwtSecret = "your-jwt-secret"
        GoogleClientId = "your-google-client-id"
        GoogleClientSecret = "your-google-client-secret"
    }
}

$envConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "$configPath/$Environment.json" -Encoding UTF8
Write-Host "Created environment configuration: $configPath/$Environment.json"

# Create .env files
if (-not (Test-Path "./frontend/.env") -or $Force) {
    @"
VITE_API_URL=http://localhost:5000
VITE_WS_URL=ws://localhost:5000
VITE_GOOGLE_CLIENT_ID=your-google-client-id
"@ | Out-File -FilePath "./frontend/.env" -Encoding UTF8
    Write-Host "Created frontend .env file"
}

if (-not (Test-Path "./backend/.env") -or $Force) {
    @"
PORT=5000
MONGODB_URI=mongodb://localhost:27017/chat
REDIS_URL=redis://localhost:6379
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
JWT_SECRET=your-jwt-secret
NODE_ENV=$Environment
"@ | Out-File -FilePath "./backend/.env" -Encoding UTF8
    Write-Host "Created backend .env file"
}

# Install dependencies
Write-Host "Installing dependencies..."

# Frontend dependencies
Write-Host "Installing frontend dependencies..."
Set-Location ./frontend
npm install
Set-Location ..

# Backend dependencies
Write-Host "Installing backend dependencies..."
Set-Location ./backend
npm install
Set-Location ..

# Create .gitignore
if (-not (Test-Path ".gitignore") -or $Force) {
    @"
# Dependencies
node_modules/
.pnp/
.pnp.js

# Testing
coverage/

# Production
build/
dist/

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Editor
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Project specific
backups/
monitoring/
quality-reports/
dependency-reports/
compliance-reports/
performance-reports/
security-reports/
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Host "Created .gitignore file"
}

# Create .dockerignore
if (-not (Test-Path ".dockerignore") -or $Force) {
    @"
# Dependencies
node_modules/
.pnp/
.pnp.js

# Testing
coverage/

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Editor
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Project specific
backups/
monitoring/
quality-reports/
dependency-reports/
compliance-reports/
performance-reports/
security-reports/
"@ | Out-File -FilePath ".dockerignore" -Encoding UTF8
    Write-Host "Created .dockerignore file"
}

# Create .editorconfig
if (-not (Test-Path ".editorconfig") -or $Force) {
    @"
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true

[*.{js,jsx,ts,tsx}]
indent_style = space
indent_size = 2

[*.{json,yml,yaml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
"@ | Out-File -FilePath ".editorconfig" -Encoding UTF8
    Write-Host "Created .editorconfig file"
}

Write-Host "`nEnvironment setup completed!"
Write-Host "Next steps:"
Write-Host "1. Update environment variables in .env files"
Write-Host "2. Start services with docker-compose up -d"
Write-Host "3. Run development servers with npm run dev" 