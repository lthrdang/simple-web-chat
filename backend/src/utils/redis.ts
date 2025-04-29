import { createClient } from 'redis'
import { logger } from './logger'

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  socket: {
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        logger.error('Redis max retries reached')
        return new Error('Redis max retries reached')
      }
      return Math.min(retries * 100, 3000)
    },
  },
})

redisClient.on('error', (error) => {
  logger.error('Redis error:', error)
})

redisClient.on('connect', () => {
  logger.info('Redis client connected')
})

redisClient.on('reconnecting', () => {
  logger.info('Redis client reconnecting')
})

redisClient.on('end', () => {
  logger.info('Redis client connection ended')
})

// Connect to Redis
redisClient.connect().catch((error) => {
  logger.error('Redis connection error:', error)
})

export { redisClient } 