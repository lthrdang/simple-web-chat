const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const User = require('../models/User');
const auth = require('../middleware/auth');

// Get all chats for a user
router.get('/', auth, async (req, res) => {
  try {
    const chats = await Chat.find({
      participants: req.user.userId
    })
    .populate('participants', 'name nickname status profilePicture')
    .sort('-lastMessage');
    res.json(chats);
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create a new chat or find existing one
router.post('/', auth, async (req, res) => {
  try {
    const { type, participants, name } = req.body;
    
    // Validate request data
    if (type === 'direct' && (!participants || participants.length !== 1)) {
      return res.status(400).json({ error: 'Direct chat requires exactly one other participant' });
    }

    if (type === 'group' && !name) {
      return res.status(400).json({ error: 'Group chat must have a name' });
    }
    
    // For direct chats, check if a chat already exists with these participants
    if (type === 'direct') {
      const otherParticipantId = participants[0];
      
      // Try to find an existing direct chat with the same participants
      const existingChat = await Chat.findOne({
        type: 'direct',
        participants: { 
          $all: [req.user.userId, otherParticipantId],
          $size: 2
        }
      }).populate('participants', 'name nickname status profilePicture');
      
      if (existingChat) {
        // Return the existing chat
        return res.json(existingChat);
      }
    }

    // Create a new chat if no existing chat was found
    const allParticipants = type === 'direct' 
      ? [participants[0], req.user.userId]
      : [...participants, req.user.userId];
    
    const chat = new Chat({
      type,
      participants: allParticipants,
      name: type === 'group' ? name : undefined,
      lastMessage: new Date()
    });

    await chat.save();
    await chat.populate('participants', 'name nickname status profilePicture');
    
    res.status(201).json(chat);
  } catch (error) {
    console.error('Error creating chat:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get chat messages
router.get('/:chatId/messages', auth, async (req, res) => {
  try {
    const chat = await Chat.findOne({
      _id: req.params.chatId,
      participants: req.user.userId
    }).populate('messages.sender', 'name nickname profilePicture');

    if (!chat) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    res.json(chat.messages);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Add message to chat
router.post('/:chatId/messages', auth, async (req, res) => {
  try {
    const { content } = req.body;
    
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Message content cannot be empty' });
    }
    
    const chat = await Chat.findOne({
      _id: req.params.chatId,
      participants: req.user.userId
    });

    if (!chat) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    // Add the new message
    const newMessage = {
      sender: req.user.userId,
      content: content.trim(),
      timestamp: new Date()
    };
    
    chat.messages.push(newMessage);
    chat.lastMessage = new Date();
    await chat.save();

    // Fetch the populated message to return
    const populatedChat = await Chat.findById(chat._id)
      .populate('messages.sender', 'name nickname profilePicture');

    const populatedMessage = populatedChat.messages[populatedChat.messages.length - 1];
    
    res.status(201).json(populatedMessage);
  } catch (error) {
    console.error('Error adding message:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 