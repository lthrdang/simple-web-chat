require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const amqp = require('amqplib');
const User = require('./models/User');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// RabbitMQ Connection
let channel;
const connectRabbitMQ = async () => {
  try {
    const connection = await amqp.connect(process.env.RABBITMQ_URL);
    channel = await connection.createChannel();
    await channel.assertQueue('chat_messages');
    console.log('Connected to RabbitMQ');
  } catch (error) {
    console.error('RabbitMQ connection error:', error);
  }
};

// Socket.IO Connection
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  let userId = null;

  // Set user ID for this socket connection
  socket.on('set_user_id', (id) => {
    userId = id;
    console.log(`User ${id} associated with socket ${socket.id}`);
    
    // Update user status to online
    if (userId) {
      updateUserStatus(userId, 'online').catch(err => {
        console.error('Error updating user status:', err);
      });
    }
  });

  socket.on('join_room', (roomId) => {
    console.log(`Socket ${socket.id} joining room ${roomId}`);
    socket.join(roomId);
  });

  socket.on('leave_room', (roomId) => {
    console.log(`Socket ${socket.id} leaving room ${roomId}`);
    socket.leave(roomId);
  });

  socket.on('send_message', async (data) => {
    const { roomId, message, sender } = data;
    
    console.log(`Message received in room ${roomId} from ${sender?.name || 'unknown'}`);
    
    // Ensure message has consistent structure and timestamp
    const messageWithTimestamp = {
      ...message,
      timestamp: message.timestamp || new Date()
    };
    
    // Publish message to RabbitMQ for processing
    if (channel) {
      channel.sendToQueue('chat_messages', Buffer.from(JSON.stringify({
        roomId,
        message: messageWithTimestamp,
        sender,
        timestamp: new Date()
      })));
    }

    // Broadcast message to room in real-time - use consistent structure
    io.to(roomId).emit('receive_message', {
      roomId,
      message: messageWithTimestamp,
      sender
    });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    
    // Update user status to offline when disconnected
    if (userId) {
      updateUserStatus(userId, 'offline').catch(err => {
        console.error('Error updating user status:', err);
      });
    }
  });
});

// Helper function to update user status
async function updateUserStatus(userId, status) {
  try {
    await User.findByIdAndUpdate(userId, {
      status,
      lastSeen: new Date()
    });
  } catch (error) {
    console.error(`Error updating status for user ${userId}:`, error);
  }
}

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/chats', require('./routes/chats'));

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  connectRabbitMQ();
}); 