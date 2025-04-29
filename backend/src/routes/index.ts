import { Express } from 'express'
import userRoutes from './userRoutes'
import chatRoutes from './chatRoutes'
import { authenticateToken } from '../middleware/auth'

export const setupRoutes = (app: Express) => {
  app.use('/api/auth', userRoutes)
  app.use('/api/chats', authenticateToken, chatRoutes)
} 