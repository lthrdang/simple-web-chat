# Check if Docker is running
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker and try again."
    exit 1
}

# Create .env files if they don't exist
if (-not (Test-Path frontend/.env)) {
    @"
VITE_API_URL=http://localhost:5000
VITE_WS_URL=ws://localhost:5000
VITE_GOOGLE_CLIENT_ID=your_google_client_id
"@ | Out-File -FilePath frontend/.env -Encoding UTF8
    Write-Host "Created frontend/.env"
}

if (-not (Test-Path backend/.env)) {
    @"
PORT=5000
MONGODB_URI=mongodb://localhost:27017/chat
REDIS_URL=redis://localhost:6379
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
JWT_SECRET=your_jwt_secret
"@ | Out-File -FilePath backend/.env -Encoding UTF8
    Write-Host "Created backend/.env"
}

# Install dependencies
Write-Host "Installing frontend dependencies..."
Set-Location frontend
npm install
Set-Location ..

Write-Host "Installing backend dependencies..."
Set-Location backend
npm install
Set-Location ..

# Start services with Docker Compose
Write-Host "Starting services with Docker Compose..."
docker-compose up -d

# Wait for services to be ready
Write-Host "Waiting for services to be ready..."
Start-Sleep -Seconds 10

# Start development servers
Write-Host "Starting development servers..."

# Start frontend in a new window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

# Start backend in a new window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm run dev"

Write-Host "Development environment is ready!"
Write-Host "Frontend: http://localhost:3000"
Write-Host "Backend: http://localhost:5000" 