param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./docs"
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Create documentation directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath
    Write-Host "Created documentation directory: $OutputPath"
}

# Generate API documentation
Write-Host "Generating API documentation..."

$apiDocs = @"
# API Documentation

## Authentication

### Google OAuth2 Login
\`\`\`http
POST /api/auth/google
Content-Type: application/json

{
  "token": "google_oauth_token"
}
\`\`\`

Response:
\`\`\`json
{
  "token": "jwt_token",
  "user": {
    "id": "user_id",
    "name": "user_name",
    "email": "user_email",
    "picture": "profile_picture_url"
  }
}
\`\`\`

## Users

### Search Users
\`\`\`http
GET /api/users/search?query=search_term
Authorization: Bearer jwt_token
\`\`\`

Response:
\`\`\`json
[
  {
    "id": "user_id",
    "name": "user_name",
    "picture": "profile_picture_url"
  }
]
\`\`\`

### Get User Status
\`\`\`http
GET /api/users/:userId/status
Authorization: Bearer jwt_token
\`\`\`

Response:
\`\`\`json
{
  "id": "user_id",
  "name": "user_name",
  "picture": "profile_picture_url",
  "status": "online|offline",
  "lastSeen": "timestamp"
}
\`\`\`

## Chats

### Create Chat
\`\`\`http
POST /api/chats
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "participants": ["user_id1", "user_id2"],
  "name": "group_name", // Optional for group chats
  "isGroup": false
}
\`\`\`

Response:
\`\`\`json
{
  "id": "chat_id",
  "name": "chat_name",
  "isGroup": false,
  "participants": [
    {
      "id": "user_id",
      "name": "user_name",
      "picture": "profile_picture_url"
    }
  ],
  "createdBy": "user_id",
  "createdAt": "timestamp"
}
\`\`\`

### Get Chats
\`\`\`http
GET /api/chats
Authorization: Bearer jwt_token
\`\`\`

Response:
\`\`\`json
[
  {
    "id": "chat_id",
    "name": "chat_name",
    "isGroup": false,
    "participants": [
      {
        "id": "user_id",
        "name": "user_name",
        "picture": "profile_picture_url"
      }
    ],
    "lastMessage": {
      "content": "message_content",
      "sender": {
        "id": "user_id",
        "name": "user_name",
        "picture": "profile_picture_url"
      },
      "timestamp": "timestamp"
    }
  }
]
\`\`\`

### Get Messages
\`\`\`http
GET /api/chats/:chatId/messages
Authorization: Bearer jwt_token
\`\`\`

Response:
\`\`\`json
[
  {
    "id": "message_id",
    "content": "message_content",
    "sender": {
      "id": "user_id",
      "name": "user_name",
      "picture": "profile_picture_url"
    },
    "timestamp": "timestamp"
  }
]
\`\`\`

### Send Message
\`\`\`http
POST /api/chats/:chatId/messages
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "content": "message_content"
}
\`\`\`

Response:
\`\`\`json
{
  "id": "message_id",
  "content": "message_content",
  "sender": {
    "id": "user_id",
    "name": "user_name",
    "picture": "profile_picture_url"
  },
  "timestamp": "timestamp"
}
\`\`\`

## WebSocket Events

### Connection
\`\`\`javascript
const socket = io('ws://localhost:5000', {
  auth: {
    token: 'jwt_token'
  }
});
\`\`\`

### Events

#### Message
\`\`\`javascript
socket.on('message', (message) => {
  console.log('New message:', message);
});
\`\`\`

#### User Typing
\`\`\`javascript
socket.on('userTyping', (data) => {
  console.log('User typing:', data);
});
\`\`\`

#### User Online/Offline
\`\`\`javascript
socket.on('userOnline', (data) => {
  console.log('User online:', data);
});

socket.on('userOffline', (data) => {
  console.log('User offline:', data);
});
\`\`\`

### Emitting Events

#### Send Message
\`\`\`javascript
socket.emit('message', {
  roomId: 'chat_id',
  content: 'message_content'
});
\`\`\`

#### Typing Status
\`\`\`javascript
socket.emit('typing', {
  roomId: 'chat_id',
  isTyping: true
});
\`\`\`
"@

$apiDocs | Out-File -FilePath "$OutputPath/api.md" -Encoding UTF8

# Generate deployment documentation
Write-Host "Generating deployment documentation..."

$deploymentDocs = @"
# Deployment Guide

## Prerequisites

- Node.js 18+
- Docker and Docker Compose
- Google Cloud SDK
- kubectl
- MongoDB Tools
- k6 (for performance testing)

## Environment Setup

1. Clone the repository:
\`\`\`bash
git clone https://github.com/yourusername/simple-web-chat.git
cd simple-web-chat
\`\`\`

2. Install dependencies:
\`\`\`bash
# Frontend
cd frontend
npm install

# Backend
cd ../backend
npm install
\`\`\`

3. Set up environment variables:
\`\`\`bash
# Frontend (.env)
VITE_API_URL=http://localhost:5000
VITE_WS_URL=ws://localhost:5000
VITE_GOOGLE_CLIENT_ID=your_google_client_id

# Backend (.env)
PORT=5000
MONGODB_URI=mongodb://localhost:27017/chat
REDIS_URL=redis://localhost:6379
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
JWT_SECRET=your_jwt_secret
\`\`\`

## Local Development

1. Start services with Docker Compose:
\`\`\`bash
docker-compose up -d
\`\`\`

2. Start development servers:
\`\`\`bash
# Frontend
cd frontend
npm run dev

# Backend
cd ../backend
npm run dev
\`\`\`

## Production Deployment

1. Set up GCP project:
\`\`\`bash
gcloud config set project your-project-id
\`\`\`

2. Initialize Terraform:
\`\`\`bash
cd terraform
terraform init
terraform apply
\`\`\`

3. Deploy to GKE:
\`\`\`bash
./scripts/deploy.ps1 -Environment prod -GcpProjectId your-project-id -GcpRegion your-region
\`\`\`

## Monitoring and Maintenance

1. Set up monitoring:
\`\`\`bash
./scripts/monitor.ps1 -Environment prod -GcpProjectId your-project-id -GcpRegion your-region
\`\`\`

2. Run performance tests:
\`\`\`bash
./scripts/performance.ps1 -Environment prod -ApiUrl your-api-url
\`\`\`

3. Check compliance:
\`\`\`bash
./scripts/compliance.ps1 -Environment prod
\`\`\`

4. Backup database:
\`\`\`bash
./scripts/backup.ps1 -Environment prod -MongoUri your-mongodb-uri
\`\`\`

## Security

1. Run security scan:
\`\`\`bash
./scripts/security.ps1 -Environment prod
\`\`\`

2. Update dependencies:
\`\`\`bash
npm audit fix
\`\`\`

## Troubleshooting

1. Check logs:
\`\`\`bash
kubectl logs deployment/frontend
kubectl logs deployment/backend
\`\`\`

2. Check service status:
\`\`\`bash
kubectl get pods
kubectl get services
\`\`\`

3. Check database connection:
\`\`\`bash
mongosh your-mongodb-uri
\`\`\`

4. Check Redis connection:
\`\`\`bash
redis-cli -u your-redis-url
\`\`\`
"@

$deploymentDocs | Out-File -FilePath "$OutputPath/deployment.md" -Encoding UTF8

# Generate architecture documentation
Write-Host "Generating architecture documentation..."

$architectureDocs = @"
# Architecture Documentation

## System Overview

The chat application is built using a microservices architecture with the following components:

- Frontend (React + Vite)
- Backend (Express.js)
- MongoDB (Database)
- Redis (Caching)
- WebSocket (Real-time communication)

## Component Diagram

\`\`\`
+----------------+     +----------------+     +----------------+
|                |     |                |     |                |
|    Frontend    |<--->|    Backend     |<--->|    MongoDB     |
|    (React)     |     |   (Express)    |     |                |
|                |     |                |     |                |
+----------------+     +----------------+     +----------------+
        ^                     ^                      ^
        |                     |                      |
        v                     v                      v
+----------------+     +----------------+     +----------------+
|                |     |                |     |                |
|   WebSocket    |<--->|     Redis      |<--->|  Google OAuth  |
|                |     |   (Cache)      |     |                |
|                |     |                |     |                |
+----------------+     +----------------+     +----------------+
\`\`\`

## Data Flow

1. User Authentication:
   - User logs in via Google OAuth2
   - Backend verifies token and creates/updates user
   - JWT token is returned to frontend

2. Real-time Communication:
   - WebSocket connection is established
   - User status is updated in Redis
   - Messages are broadcasted to connected clients

3. Message Flow:
   - User sends message
   - Backend validates and stores in MongoDB
   - Message is broadcasted via WebSocket
   - Recipients receive real-time update

## Security Measures

1. Authentication:
   - JWT-based authentication
   - Google OAuth2 integration
   - Token refresh mechanism

2. Data Protection:
   - HTTPS/TLS encryption
   - Data encryption at rest
   - Input sanitization
   - Rate limiting

3. Compliance:
   - GDPR compliance
   - Data retention policies
   - User consent management
   - Data portability

## Scalability

1. Horizontal Scaling:
   - Stateless backend services
   - Load balancing
   - Database sharding
   - Redis cluster

2. Performance Optimization:
   - Caching with Redis
   - Database indexing
   - Connection pooling
   - Message queuing

## Monitoring

1. Metrics:
   - CPU/Memory usage
   - Request latency
   - Error rates
   - User activity

2. Logging:
   - Application logs
   - Error tracking
   - Audit trails
   - Performance metrics

## Disaster Recovery

1. Backup Strategy:
   - Daily database backups
   - Point-in-time recovery
   - Cross-region replication

2. High Availability:
   - Multi-zone deployment
   - Failover mechanisms
   - Data replication
   - Service redundancy
"@

$architectureDocs | Out-File -FilePath "$OutputPath/architecture.md" -Encoding UTF8

Write-Host "`nDocumentation generation completed!"
Write-Host "API documentation: $OutputPath/api.md"
Write-Host "Deployment guide: $OutputPath/deployment.md"
Write-Host "Architecture documentation: $OutputPath/architecture.md" 