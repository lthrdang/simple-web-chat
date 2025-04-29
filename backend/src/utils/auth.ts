import jwt from 'jsonwebtoken'
import { AppError } from '../middleware/errorHandler'

interface User {
  id: string
  name: string
  email: string
  picture: string
}

interface TokenPayload {
  userId: string
  email: string
}

export const generateToken = (user: User): string => {
  const payload: TokenPayload = {
    userId: user.id,
    email: user.email,
  }

  return jwt.sign(payload, process.env.JWT_SECRET || 'your-secret-key', {
    expiresIn: '7d',
  })
}

export const verifyToken = async (token: string): Promise<User> => {
  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || 'your-secret-key'
    ) as TokenPayload

    // Get user from database
    const user = await getUserById(decoded.userId)
    if (!user) {
      throw new AppError(401, 'User not found')
    }

    return user
  } catch (error) {
    throw new AppError(401, 'Invalid token')
  }
}

// This is a placeholder function - implement actual database query
const getUserById = async (userId: string): Promise<User | null> => {
  // Replace with actual database query
  return null
} 