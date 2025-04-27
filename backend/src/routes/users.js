const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');
const { fuzzySearch } = require('../utils/fuzzySearch');

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { nickname, status } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { 
        nickname: nickname || undefined,
        status: status || undefined,
        lastSeen: new Date()
      },
      { new: true }
    );
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Search users with approximate matching
router.get('/search', auth, async (req, res) => {
  try {
    const { query } = req.query;
    
    // If query is empty, return empty results
    if (!query || !query.trim()) {
      return res.json([]);
    }
    
    // First fetch all users except the current user
    const allUsers = await User.find({
      _id: { $ne: req.user.userId }
    }).select('-googleId -email');
    
    // Apply fuzzy search to the results
    const searchResults = fuzzySearch(
      allUsers, 
      query, 
      ['name', 'nickname'],
      // Adjust the threshold based on query length
      query.length < 3 ? 1 : 2
    );
    
    // Return only the top results (limit to 10)
    res.json(searchResults.slice(0, 10));
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 