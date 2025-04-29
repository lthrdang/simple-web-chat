import { Request, Response, NextFunction } from 'express'
import { OAuth2Client } from 'google-auth-library'
import { User, IUser } from '../models/User'
import { AppError } from '../middleware/errorHandler'
import { generateToken } from '../utils/auth'
import { redisClient } from '../utils/redis'
import { logger } from '../utils/logger'

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID)

export const googleAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { token } = req.body

    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: process.env.GOOGLE_CLIENT_ID,
    })

    const payload = ticket.getPayload()
    if (!payload) {
      throw new AppError(401, 'Invalid token')
    }

    const { sub: googleId, email, name, picture } = payload

    // Find or create user
    let user = await User.findOne({ googleId })

    if (!user) {
      user = await User.create({
        googleId,
        email,
        name,
        picture,
        status: 'online',
      })
    }

    try {
      // Update user status in Redis
      await redisClient.set(`user:${user._id}:status`, 'online')
      await redisClient.expire(`user:${user._id}:status`, 300) // 5 minutes
    } catch (redisError) {
      logger.error('Redis error during user status update:', redisError)
      // Continue with the response even if Redis update fails
    }

    // Generate JWT
    const authToken = generateToken(user)

    res.json({
      token: authToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        picture: user.picture,
      },
    })
  } catch (error) {
    next(error)
  }
}

export const searchUsers = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { q } = req.query
    if (!q || typeof q !== 'string') {
      throw new AppError(400, 'Search query is required')
    }

    // Split search query into words for better matching
    const searchTerms = q.split(/\s+/).filter(term => term.length > 0)
    
    // Build search query with fuzzy matching
    const searchQuery = {
      $or: [
        { $text: { $search: q } }, // Exact text search
        ...searchTerms.map(term => ({
          $or: [
            { name: { $regex: term, $options: 'i' } }, // Case-insensitive regex match
            { email: { $regex: term, $options: 'i' } }  // Case-insensitive regex match
          ]
        }))
      ]
    }

    const users = await User.find(searchQuery)
      .sort({ score: { $meta: 'textScore' } })
      .limit(10)
      .select('-googleId')

    // Format the response to match frontend expectations
    const formattedUsers = users.map(user => ({
      id: user._id,
      name: user.name,
      picture: user.picture,
      lastMessage: '',
      unreadCount: 0,
      isGroup: false,
      email: user.email // Include email for better context
    }))

    res.json(formattedUsers)
  } catch (error) {
    next(error)
  }
}

export const getUserStatus = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { userId } = req.params

    let status = 'offline'
    try {
      status = await redisClient.get(`user:${userId}:status`) || 'offline'
    } catch (redisError) {
      logger.error('Redis error during status check:', redisError)
    }

    const user = await User.findById(userId).select('name picture lastSeen')

    if (!user) {
      throw new AppError(404, 'User not found')
    }

    res.json({
      ...user.toJSON(),
      status,
    })
  } catch (error) {
    next(error)
  }
} 