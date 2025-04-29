import { Server, Socket } from 'socket.io'
import { logger } from '../utils/logger'
import { verifyToken } from '../utils/auth'
import { redisClient } from '../utils/redis'

interface User {
  id: string
  name: string
  picture: string
}

export const setupWebSocket = (io: Server) => {
  io.use(async (socket: Socket, next) => {
    try {
      const token = socket.handshake.auth.token
      if (!token) {
        throw new Error('Authentication error')
      }

      const user = await verifyToken(token)
      socket.data.user = user
      next()
    } catch (error) {
      next(new Error('Authentication error'))
    }
  })

  io.on('connection', async (socket: Socket) => {
    const user = socket.data.user as User

    logger.info(`User connected: ${user.name}`)

    // Update user status
    await redisClient.set(`user:${user.id}:status`, 'online')
    await redisClient.expire(`user:${user.id}:status`, 300) // 5 minutes

    // Join user's rooms
    const rooms = await redisClient.sMembers(`user:${user.id}:rooms`)
    rooms.forEach((room) => {
      socket.join(room)
    })

    // Handle chat messages
    socket.on('message', async (data: { roomId: string; content: string }) => {
      try {
        // Save message to database (handled by message service)
        // Broadcast to room
        io.to(data.roomId).emit('message', {
          content: data.content,
          sender: {
            id: user.id,
            name: user.name,
            picture: user.picture,
          },
          timestamp: new Date().toISOString(),
        })
      } catch (error) {
        logger.error('Error handling message:', error)
      }
    })

    // Handle typing status
    socket.on('typing', (data: { roomId: string; isTyping: boolean }) => {
      socket.to(data.roomId).emit('userTyping', {
        userId: user.id,
        name: user.name,
        isTyping: data.isTyping,
      })
    })

    // Handle disconnection
    socket.on('disconnect', async () => {
      logger.info(`User disconnected: ${user.name}`)
      await redisClient.del(`user:${user.id}:status`)
      io.emit('userOffline', { userId: user.id })
    })
  })
} 