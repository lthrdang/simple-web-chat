import { useState, useEffect, useRef } from 'react';
import { Box, Grid, Paper, TextField, IconButton, Typography, Avatar, List, ListItem, ListItemAvatar, ListItemText, Divider, CircularProgress, Chip, Snackbar, Alert, Button, Tooltip } from '@mui/material';
import { Send as SendIcon, Search as SearchIcon, Clear as ClearIcon, PersonAdd as PersonAddIcon, Logout as LogoutIcon } from '@mui/icons-material';
import { io } from 'socket.io-client';
import axios from 'axios';
import { useAuth } from '../hooks/useAuth';
import { debugLog } from '../debug';

function Chat() {
  const { user, logout } = useAuth();
  const [chats, setChats] = useState([]);
  const [selectedChat, setSelectedChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const searchTimeoutRef = useRef(null);
  const socketRef = useRef();
  const messagesEndRef = useRef(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'info' });
  const [sentMessageIds, setSentMessageIds] = useState(new Set());

  useEffect(() => {
    debugLog('socket', 'Initializing socket connection');
    socketRef.current = io(import.meta.env.VITE_API_URL, {
      debug: true,
      autoConnect: true
    });
    
    socketRef.current.on('connect', () => {
      debugLog('socket', 'Connected to socket server', { socketId: socketRef.current.id });
      
      // Set user ID for the socket connection
      if (user && user._id) {
        debugLog('socket', 'Setting user ID in socket', { userId: user._id });
        socketRef.current.emit('set_user_id', user._id);
      }
    });

    socketRef.current.on('connect_error', (error) => {
      debugLog('error', 'Socket connection error', error);
    });

    socketRef.current.on('disconnect', (reason) => {
      debugLog('socket', 'Disconnected from socket server', { reason });
    });

    socketRef.current.on('receive_message', (data) => {
      debugLog('socket', 'Received message', data);
      
      if (data.roomId === selectedChat?._id) {
        const receivedMessageId = data.message._id;

        // Check if this is a message we just sent (to avoid duplicates)
        if (sentMessageIds.has(receivedMessageId)) {
          debugLog('socket', 'Ignoring duplicate message that we sent', {
            messageId: receivedMessageId
          });
          return;
        }
        
        // Otherwise, add the message to our state
        setMessages(prev => [...prev, data.message]);
      }
    });

    return () => {
      debugLog('socket', 'Cleaning up socket connection');
      socketRef.current.disconnect();
    };
  }, [selectedChat, user, sentMessageIds]);

  useEffect(() => {
    fetchChats();
  }, []);

  useEffect(() => {
    if (selectedChat) {
      fetchMessages();
      socketRef.current.emit('join_room', selectedChat._id);
    }
    return () => {
      if (selectedChat) {
        socketRef.current.emit('leave_room', selectedChat._id);
      }
    };
  }, [selectedChat]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchChats = async () => {
    try {
      debugLog('api', 'Fetching all chats');
      const response = await axios.get(`${import.meta.env.VITE_API_URL}/api/chats`);
      debugLog('api', 'Chats fetched successfully', { count: response.data.length });
      setChats(response.data);
    } catch (error) {
      debugLog('error', 'Error fetching chats:', error);
      console.error('Error fetching chats:', error);
    }
  };

  const fetchMessagesForChat = async (chatId) => {
    try {
      debugLog('api', 'Fetching messages for chat', { chatId });
      const response = await axios.get(`${import.meta.env.VITE_API_URL}/api/chats/${chatId}/messages`);
      debugLog('api', 'Messages fetched successfully', { count: response.data.length });
      setMessages(response.data);
      setTimeout(scrollToBottom, 100);
    } catch (error) {
      debugLog('error', 'Error fetching messages:', error);
      console.error('Error fetching messages:', error);
    }
  };

  const fetchMessages = async () => {
    if (!selectedChat) return;
    await fetchMessagesForChat(selectedChat._id);
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedChat) return;

    try {
      debugLog('api', 'Sending message', { 
        chatId: selectedChat._id,
        content: newMessage.substring(0, 20) + (newMessage.length > 20 ? '...' : '')
      });
      
      const response = await axios.post(`${import.meta.env.VITE_API_URL}/api/chats/${selectedChat._id}/messages`, {
        content: newMessage
      });

      const messageId = response.data._id;
      debugLog('api', 'Message sent successfully', { messageId });

      // Track this message ID to avoid duplicates
      setSentMessageIds(prev => new Set(prev).add(messageId));

      // Update the message in the current chat list for UI consistency
      const updatedChats = chats.map(chat => {
        if (chat._id === selectedChat._id) {
          // Create a shallow copy of messages to avoid direct state mutation
          const updatedMessages = [...chat.messages, response.data];
          return { ...chat, messages: updatedMessages };
        }
        return chat;
      });
      setChats(updatedChats);

      // Emit the message to socket.io for real-time updates
      debugLog('socket', 'Emitting message to socket', { 
        roomId: selectedChat._id,
        messageId: response.data._id 
      });
      
      socketRef.current.emit('send_message', {
        roomId: selectedChat._id,
        message: response.data,
        sender: user
      });

      // Add the message to the current messages display
      setMessages(prev => [...prev, response.data]);
      setNewMessage('');
      
      // Scroll to bottom after new message
      setTimeout(scrollToBottom, 50);

      // Clean up sent message IDs after a delay to prevent memory leaks
      setTimeout(() => {
        setSentMessageIds(prev => {
          const newSet = new Set(prev);
          newSet.delete(messageId);
          return newSet;
        });
      }, 30000); // Clean up after 30 seconds
    } catch (error) {
      debugLog('error', 'Error sending message:', error);
      console.error('Error sending message:', error);
      setSnackbar({
        open: true,
        message: 'Failed to send message',
        severity: 'error'
      });
    }
  };

  const handleSearchInputChange = (e) => {
    const value = e.target.value;
    setSearchQuery(value);
    
    // Clear any pending search
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }
    
    if (!value.trim()) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }
    
    setIsSearching(true);
    
    // Debounce search to avoid too many requests
    searchTimeoutRef.current = setTimeout(() => {
      debugLog('api', 'Debounced search triggered', { query: value });
      performSearch(value);
    }, 300);
  };
  
  const performSearch = async (query) => {
    try {
      debugLog('api', 'Performing user search', { query });
      const response = await axios.get(`${import.meta.env.VITE_API_URL}/api/users/search?query=${query}`);
      debugLog('api', 'Search completed', { resultCount: response.data.length });
      setSearchResults(response.data);
      setIsSearching(false);
    } catch (error) {
      debugLog('error', 'Error searching users:', error);
      console.error('Error searching users:', error);
      setIsSearching(false);
    }
  };

  const handleCreateChat = async (userId) => {
    try {
      debugLog('api', 'Checking for existing chat with user', { userId });
      
      // First check if a chat with this user already exists
      const existingChat = chats.find(chat => 
        chat.type === 'direct' && 
        chat.participants.some(p => p._id === userId)
      );
      
      if (existingChat) {
        debugLog('api', 'Found existing chat, selecting it', { chatId: existingChat._id });
        // If chat exists, just select it
        setSelectedChat(existingChat);
        setSearchResults([]);
        setSearchQuery('');
        setSnackbar({
          open: true,
          message: 'Chat already exists',
          severity: 'info'
        });
        return;
      }
      
      // Create new chat
      debugLog('api', 'Creating new chat with user', { userId });
      setSnackbar({
        open: true,
        message: 'Creating new chat...',
        severity: 'info'
      });
      
      const response = await axios.post(`${import.meta.env.VITE_API_URL}/api/chats`, {
        type: 'direct',
        participants: [userId]
      });
      
      debugLog('api', 'Chat created successfully', { chatId: response.data._id });
      
      // Add the new chat to the list
      const newChat = response.data;
      setChats(prev => [newChat, ...prev]);
      
      // Select the new chat
      setSelectedChat(newChat);
      setSearchResults([]);
      setSearchQuery('');
      
      // Fetch messages for this chat to ensure correct initialization
      fetchMessagesForChat(newChat._id);
      
      setSnackbar({
        open: true,
        message: 'New chat created',
        severity: 'success'
      });
    } catch (error) {
      debugLog('error', 'Error creating chat:', error);
      console.error('Error creating chat:', error);
      setSnackbar({
        open: true,
        message: 'Failed to create chat',
        severity: 'error'
      });
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSnackbarClose = (event, reason) => {
    if (reason === 'clickaway') return;
    setSnackbar({ ...snackbar, open: false });
  };

  const handleLogout = () => {
    logout();
  };

  return (
    <Grid container sx={{ height: '100vh' }}>
      {/* Sidebar */}
      <Grid item xs={12} md={4} sx={{ borderRight: 1, borderColor: 'divider' }}>
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: 1, borderColor: 'divider' }}>
          <Typography variant="h6">Chats</Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Avatar
              src={user?.profilePicture} 
              alt={user?.name}
              sx={{ width: 32, height: 32 }}
            >
              {user?.name?.charAt(0).toUpperCase()}
            </Avatar>
            <Typography variant="body2" color="text.secondary" noWrap>
              {user?.nickname || user?.name}
            </Typography>
            <Tooltip title="Logout">
              <IconButton color="primary" onClick={handleLogout}>
                <LogoutIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
        <Box sx={{ p: 2 }}>
          <TextField
            fullWidth
            variant="outlined"
            placeholder="Search users..."
            value={searchQuery}
            onChange={handleSearchInputChange}
            InputProps={{
              endAdornment: (
                isSearching ? (
                  <CircularProgress size={24} />
                ) : searchQuery ? (
                  <IconButton onClick={() => {
                    setSearchQuery('');
                    setSearchResults([]);
                  }}>
                    <ClearIcon />
                  </IconButton>
                ) : (
                  <SearchIcon color="disabled" />
                )
              ),
            }}
          />
        </Box>

        {searchQuery ? (
          <Box>
            {isSearching ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
                <CircularProgress size={30} />
              </Box>
            ) : searchResults.length > 0 ? (
              <>
                <Typography variant="subtitle2" sx={{ px: 2, py: 1, color: 'text.secondary' }}>
                  Search Results ({searchResults.length})
                </Typography>
                <List>
                  {searchResults.map((user) => (
                    <ListItem
                      key={user._id}
                      button
                      sx={{
                        transition: 'background-color 0.2s',
                        '&:hover': {
                          backgroundColor: 'rgba(25, 118, 210, 0.08)',
                        },
                      }}
                      secondaryAction={
                        <IconButton edge="end" onClick={() => handleCreateChat(user._id)}>
                          <PersonAddIcon />
                        </IconButton>
                      }
                    >
                      <ListItemAvatar>
                        <Avatar src={user.profilePicture} alt={user.name}>
                          {user.name.charAt(0).toUpperCase()}
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={
                          <Box component="span" sx={{ display: 'flex', alignItems: 'center' }}>
                            {user.nickname || user.name}
                            {user.status === 'online' && (
                              <Box
                                component="span"
                                sx={{
                                  width: 8,
                                  height: 8,
                                  bgcolor: 'success.main',
                                  borderRadius: '50%',
                                  display: 'inline-block',
                                  ml: 1,
                                }}
                              />
                            )}
                          </Box>
                        }
                        secondary={
                          user.nickname && user.nickname !== user.name ? user.name : user.status
                        }
                      />
                    </ListItem>
                  ))}
                </List>
              </>
            ) : (
              <Box sx={{ p: 2, textAlign: 'center' }}>
                <Typography color="text.secondary">No users found</Typography>
                <Typography variant="caption" color="text.secondary">
                  Try a different search term
                </Typography>
              </Box>
            )}
          </Box>
        ) : (
          <List>
            {chats.map((chat) => (
              <ListItem
                key={chat._id}
                button
                selected={selectedChat?._id === chat._id}
                onClick={() => setSelectedChat(chat)}
              >
                <ListItemAvatar>
                  <Avatar src={chat.type === 'direct' ? chat.participants.find(p => p._id !== user._id)?.profilePicture : ''}>
                    {(chat.type === 'direct' ? chat.participants.find(p => p._id !== user._id)?.name : chat.name)?.charAt(0).toUpperCase()}
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={chat.type === 'direct' ? chat.participants.find(p => p._id !== user._id)?.nickname || chat.participants.find(p => p._id !== user._id)?.name : chat.name}
                  secondary={chat.messages[chat.messages.length - 1]?.content}
                />
              </ListItem>
            ))}
          </List>
        )}
      </Grid>

      {/* Chat Area */}
      <Grid item xs={12} md={8}>
        {selectedChat ? (
          <>
            <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
              <Typography variant="h6">
                {selectedChat.type === 'direct'
                  ? selectedChat.participants.find(p => p._id !== user._id)?.nickname || selectedChat.participants.find(p => p._id !== user._id)?.name
                  : selectedChat.name}
              </Typography>
            </Box>

            <Box sx={{ height: 'calc(100vh - 180px)', overflow: 'auto', p: 2 }}>
              {messages.map((message, index) => (
                <Box
                  key={index}
                  sx={{
                    display: 'flex',
                    justifyContent: message.sender._id === user._id ? 'flex-end' : 'flex-start',
                    mb: 2,
                  }}
                >
                  <Paper
                    sx={{
                      p: 2,
                      maxWidth: '70%',
                      bgcolor: message.sender._id === user._id ? 'primary.main' : 'grey.100',
                      color: message.sender._id === user._id ? 'white' : 'text.primary',
                    }}
                  >
                    <Typography variant="body1">{message.content}</Typography>
                    <Typography variant="caption" sx={{ display: 'block', mt: 1 }}>
                      {new Date(message.timestamp).toLocaleTimeString()}
                    </Typography>
                  </Paper>
                </Box>
              ))}
              <div ref={messagesEndRef} />
            </Box>

            <Box
              component="form"
              onSubmit={handleSendMessage}
              sx={{
                p: 2,
                borderTop: 1,
                borderColor: 'divider',
                display: 'flex',
                gap: 1,
              }}
            >
              <TextField
                fullWidth
                variant="outlined"
                placeholder="Type a message..."
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
              />
              <IconButton type="submit" color="primary">
                <SendIcon />
              </IconButton>
            </Box>
          </>
        ) : (
          <Box
            sx={{
              height: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Typography variant="h6" color="text.secondary">
              Select a chat or start a new conversation
            </Typography>
          </Box>
        )}
      </Grid>

      {/* Add Snackbar for notifications */}
      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={3000} 
        onClose={handleSnackbarClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
      >
        <Alert onClose={handleSnackbarClose} severity={snackbar.severity} sx={{ width: '100%' }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Grid>
  );
}

export default Chat; 