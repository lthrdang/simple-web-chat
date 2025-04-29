import express from 'express'
import { createServer } from 'http'
import { Server } from 'socket.io'
import cors from 'cors'
import helmet from 'helmet'
import rateLimit from 'express-rate-limit'
import dotenv from 'dotenv'
import mongoose from 'mongoose'
import { createClient } from 'redis'
import { setupRoutes } from './routes'
import { setupWebSocket } from './services/websocket'
import { errorHandler } from './middleware/errorHandler'
import { logger } from './utils/logger'

dotenv.config()

// Debug mode configuration
const DEBUG_MODE = process.env.DEBUG_MODE === 'true'
if (DEBUG_MODE) {
  logger.info('Debug mode is enabled')
  mongoose.set('debug', true)
}

const app = express()
const httpServer = createServer(app)
const io = new Server(httpServer, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST'],
    credentials: true,
  },
})

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  crossOriginOpenerPolicy: { policy: "unsafe-none" },
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://accounts.google.com"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://accounts.google.com"],
      frameSrc: ["'self'", "https://accounts.google.com"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
}))
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}))
app.use(express.json())
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
}))

// Enhanced logging middleware for debug mode
if (DEBUG_MODE) {
  app.use((req, res, next) => {
    logger.debug(`${req.method} ${req.url}`, {
      headers: req.headers,
      body: req.body,
      query: req.query,
    })
    next()
  })
}

// Routes
setupRoutes(app)

// Error handling
app.use(errorHandler)

// WebSocket setup
setupWebSocket(io)

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/chat')
  .then(() => logger.info('Connected to MongoDB'))
  .catch((error) => logger.error('MongoDB connection error:', error))

// Redis connection
const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
})

redisClient.connect()
  .then(() => logger.info('Connected to Redis'))
  .catch((error) => logger.error('Redis connection error:', error))

// Start server
const PORT = process.env.PORT || 5000
httpServer.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}${DEBUG_MODE ? ' (Debug Mode)' : ''}`)
}) 