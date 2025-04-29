param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$GcpProjectId,
    
    [Parameter(Mandatory=$true)]
    [string]$GcpRegion
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if gcloud is installed
$gcloudStatus = gcloud version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Google Cloud SDK is not installed. Please install it and try again."
    exit 1
}

# Check if kubectl is installed
$kubectlStatus = kubectl version --client 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl is not installed. Please install it and try again."
    exit 1
}

# Set Google Cloud project
Write-Host "Setting Google Cloud project..."
gcloud config set project $GcpProjectId

# Get GKE credentials
Write-Host "Getting GKE credentials..."
gcloud container clusters get-credentials "$GcpProjectId-gke" --region $GcpRegion

# Build and push Docker images
Write-Host "Building and pushing Docker images..."
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Frontend
Write-Host "Building frontend image..."
docker build -t "gcr.io/$GcpProjectId/frontend:$timestamp" -t "gcr.io/$GcpProjectId/frontend:latest" ./frontend
docker push "gcr.io/$GcpProjectId/frontend:$timestamp"
docker push "gcr.io/$GcpProjectId/frontend:latest"

# Backend
Write-Host "Building backend image..."
docker build -t "gcr.io/$GcpProjectId/backend:$timestamp" -t "gcr.io/$GcpProjectId/backend:latest" ./backend
docker push "gcr.io/$GcpProjectId/backend:$timestamp"
docker push "gcr.io/$GcpProjectId/backend:latest"

# Update Kubernetes manifests
Write-Host "Updating Kubernetes manifests..."
$frontendYaml = Get-Content ./kubernetes/frontend.yaml
$frontendYaml = $frontendYaml -replace "image: frontend:latest", "image: gcr.io/$GcpProjectId/frontend:$timestamp"
$frontendYaml | Set-Content ./kubernetes/frontend.yaml

$backendYaml = Get-Content ./kubernetes/backend.yaml
$backendYaml = $backendYaml -replace "image: backend:latest", "image: gcr.io/$GcpProjectId/backend:$timestamp"
$backendYaml | Set-Content ./kubernetes/backend.yaml

# Apply Kubernetes manifests
Write-Host "Applying Kubernetes manifests..."
kubectl apply -f ./kubernetes/

# Wait for deployments to be ready
Write-Host "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend deployment/backend

# Get service endpoints
$frontendIp = kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$backendIp = kubectl get service backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

Write-Host "Deployment completed successfully!"
Write-Host "Frontend: http://$frontendIp"
Write-Host "Backend: http://$backendIp" 