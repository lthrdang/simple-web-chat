import { Router } from 'express'
import {
  createChat,
  getChats,
  getMessages,
  sendMessage,
} from '../controllers/chatController'

const router = Router()

// Chat routes
router.post('/', createChat)
router.get('/', getChats)
router.get('/:chatId/messages', getMessages)
router.post('/:chatId/messages', sendMessage)

export default router 