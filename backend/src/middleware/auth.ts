import { Request, Response, NextFunction } from 'express'
import { verifyToken } from '../utils/auth'
import { AppError } from './errorHandler'

declare global {
  namespace Express {
    interface Request {
      user?: any
    }
  }
}

export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization
    const token = authHeader && authHeader.split(' ')[1]

    if (!token) {
      throw new AppError(401, 'Authentication required')
    }

    const user = await verifyToken(token)
    req.user = user
    next()
  } catch (error) {
    next(new AppError(401, 'Invalid token'))
  }
} 