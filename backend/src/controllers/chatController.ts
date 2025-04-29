import { Request, Response, NextFunction } from 'express'
import { Types } from 'mongoose'
import { Chat, IChat } from '../models/Chat'
import { User } from '../models/User'
import { AppError } from '../middleware/errorHandler'
import { redisClient } from '../utils/redis'

export const createChat = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { participants, name, isGroup } = req.body
    const userId = req.user._id

    if (!participants || !Array.isArray(participants)) {
      throw new AppError(400, 'Participants are required')
    }

    if (isGroup && !name) {
      throw new AppError(400, 'Group name is required')
    }

    // Validate participants
    const validParticipants = await User.find({
      _id: { $in: participants },
    }).select('_id')

    if (validParticipants.length !== participants.length) {
      throw new AppError(400, 'Invalid participants')
    }

    // Create chat
    const chat = await Chat.create({
      name: isGroup ? name : undefined,
      isGroup,
      participants: [...validParticipants.map(p => p._id), userId],
      createdBy: userId,
    })

    // Add chat to Redis for each participant
    await Promise.all(
      chat.participants.map(async (participantId) => {
        await redisClient.sAdd(
          `user:${participantId}:rooms`,
          chat._id.toString()
        )
      })
    )

    await chat.populate('participants', 'name picture')

    res.status(201).json(chat)
  } catch (error) {
    next(error)
  }
}

export const getChats = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const userId = req.user._id

    const chats = await Chat.find({
      participants: userId,
    })
      .populate('participants', 'name picture status')
      .populate('lastMessage')
      .sort('-updatedAt')

    res.json(chats)
  } catch (error) {
    next(error)
  }
}

export const getMessages = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { chatId } = req.params
    const userId = req.user._id

    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    }).populate({
      path: 'messages.sender',
      select: 'name picture',
    })

    if (!chat) {
      throw new AppError(404, 'Chat not found')
    }

    res.json(chat.messages)
  } catch (error) {
    next(error)
  }
}

export const sendMessage = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { chatId } = req.params
    const { content } = req.body
    const userId = req.user._id

    if (!content) {
      throw new AppError(400, 'Message content is required')
    }

    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    })

    if (!chat) {
      throw new AppError(404, 'Chat not found')
    }

    const message = {
      sender: userId,
      content,
      readBy: [userId],
    }

    chat.messages.push(message)
    await chat.save()

    // Populate sender info for the response
    const populatedMessage = await Chat.populate(message, {
      path: 'sender',
      select: 'name picture',
    })

    res.status(201).json(populatedMessage)
  } catch (error) {
    next(error)
  }
} 