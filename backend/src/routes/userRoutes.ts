import { Router } from 'express'
import { googleAuth, searchUsers, getUserStatus } from '../controllers/userController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

// Auth routes
router.post('/google', googleAuth)

// Protected routes
router.use(authenticateToken)
router.get('/search', searchUsers)
router.get('/:userId/status', getUserStatus)

export default router 