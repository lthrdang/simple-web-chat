# Simple Web Chat Application

A real-time chat application built with React, Express, MongoDB, and Socket.IO.

## Features

- Google Authentication
- Real-time messaging
- User search
- Online/offline status
- Responsive design for all devices
- Direct and group chat support

## Prerequisites

- Node.js (v18 or higher)
- Docker and Docker Compose
- Google Cloud Platform account with OAuth 2.0 credentials

## Setting Up Google OAuth2 Client ID

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" and select "OAuth client ID"
5. If this is your first time, you'll need to configure the consent screen:
   - Click "Configure Consent Screen"
   - Select "External" user type (unless you are in a Google Workspace organization)
   - Fill in the required application information (name, support email, etc.)
   - Add the "/auth/userinfo.email" and "/auth/userinfo.profile" scopes
   - Add any test users for development
   - Complete the setup

6. Return to "Credentials" and click "Create Credentials" > "OAuth client ID"
7. Choose "Web application" as the application type
8. Give your client a name (e.g., "Chat App")
9. Add authorized JavaScript origins:
   - For development: `http://localhost:3000`
   - For production: your production domain

10. Add authorized redirect URIs:
    - For development: `http://localhost:3000`
    - For production: your production domain

11. Click "Create"
12. You will receive your Client ID and Client Secret
13. Copy these values to your `.env` file:
    ```
    GOOGLE_CLIENT_ID=your_client_id_here
    GOOGLE_CLIENT_SECRET=your_client_secret_here
    ```

> **Note**: For security reasons, never commit your `.env` file to your repository!

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# JWT
JWT_SECRET=your_jwt_secret

# MongoDB
MONGODB_URI=mongodb://mongo:27017/chat_app

# RabbitMQ
RABBITMQ_URL=amqp://rabbitmq
```

## Getting Started

1. Clone the repository:
```bash
git clone <repository-url>
cd simple-web-chat
```

2. Start the application using Docker Compose:
```bash
docker-compose up --build
```

3. Access the application:
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000
- RabbitMQ Management: http://localhost:15672 (guest/guest)

## Development

### Frontend

The frontend is built with React and Vite. To run it in development mode:

```bash
cd frontend
npm install
npm run dev
```

### Backend

The backend is built with Express.js. To run it in development mode:

```bash
cd backend
npm install
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/google` - Google OAuth login

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/search` - Search users

### Chats
- `GET /api/chats` - Get all chats
- `POST /api/chats` - Create new chat
- `GET /api/chats/:chatId/messages` - Get chat messages
- `POST /api/chats/:chatId/messages` - Send message

## Technologies Used

- Frontend:
  - React
  - Material-UI
  - Socket.IO Client
  - Axios

- Backend:
  - Express.js
  - Socket.IO
  - MongoDB
  - RabbitMQ
  - JWT Authentication

- Infrastructure:
  - Docker
  - Docker Compose

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. 