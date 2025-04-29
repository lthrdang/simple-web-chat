# Simple Web Chat

A production-grade chat application with compliance and security in mind. Built with React, Express, MongoDB, and WebSockets.

## Features

- Google OAuth2 authentication with One Tap Sign-In
- Real-time chat with WebSocket support
- User presence and status indicators
- Fuzzy search for users
- 1:1 and group chat support
- Responsive design (320px - 1440px)
- Encrypted data storage
- High-performance caching with Redis
- Docker containerization for easy deployment
- Development and production environments

## Tech Stack

- **Frontend**: 
  - React.js (Vite)
  - Tailwind CSS
  - Google Sign-In API
  - Socket.IO Client
  - Zustand for state management
- **Backend**: 
  - Express.js (Node.js)
  - TypeScript
  - Socket.IO
  - Google Auth Library
  - JWT for authentication
- **Database**: MongoDB (encrypted at rest)
- **Real-time**: WebSockets
- **Cache**: Redis
- **Containerization**: Docker Compose
- **Infrastructure**: Terraform (GCP GKE)
- **CI/CD**: Azure DevOps

## Prerequisites

- Node.js 18+
- Docker and Docker Compose
- Google Cloud Platform account
- Azure DevOps account
- MongoDB Atlas account (or local MongoDB)

## Environment Variables

Create a `.env` file in the root directory:

```
# Frontend
VITE_API_URL=http://localhost:5000
VITE_WS_URL=ws://localhost:5000
VITE_GOOGLE_CLIENT_ID=your_google_client_id

# Backend
PORT=5000
MONGODB_URI=mongodb://localhost:27017/chat
REDIS_URL=redis://localhost:6379
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
JWT_SECRET=your_jwt_secret
```

## Google OAuth Configuration

1. Go to the Google Cloud Console (https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the Google Sign-In API
4. Create OAuth 2.0 credentials
5. Add authorized JavaScript origins:
   - `http://localhost:3000`
   - `http://127.0.0.1:3000`
   - `http://localhost`
   - `http://127.0.0.1`
6. Add authorized redirect URIs:
   - `http://localhost:3000`
   - `http://localhost:5000/api/auth/google/callback`

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/simple-web-chat.git
cd simple-web-chat
```

2. Set up environment variables:
```bash
# Copy the example .env file
cp .env.example .env
# Edit the .env file with your credentials
```

3. Start development servers:
```bash
# Using Docker Compose (recommended)
docker-compose up

# Or run services separately
# Frontend
cd frontend
npm run dev

# Backend
cd backend
npm run dev
```

4. Access the application:
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

## Security Checklist

- [ ] HTTPS enabled in production
- [ ] Input sanitization implemented
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] JWT token validation
- [ ] Data encryption at rest
- [ ] Secure WebSocket connections
- [ ] Environment variables properly set
- [ ] Regular security audits
- [ ] GDPR compliance measures
- [ ] Google OAuth properly configured
- [ ] Secure session management

## Compliance Considerations

- Data encryption at rest and in transit
- User consent management
- Data retention policies
- Privacy policy implementation
- GDPR compliance measures
- Regular security audits
- Data backup procedures
- OAuth2 security best practices
- Session management security

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details 