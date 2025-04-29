import { useState, useEffect, useRef } from 'react'
import { useParams } from 'react-router-dom'
import { PaperAirplaneIcon } from '@heroicons/react/24/outline'
import { useAuth } from '../hooks/useAuth'

interface Message {
  id: string
  content: string
  sender: {
    id: string
    name: string
    picture: string
  }
  timestamp: string
}

export default function Chat() {
  const { chatId } = useParams()
  const { user } = useAuth()
  const [messages, setMessages] = useState<Message[]>([])
  const [newMessage, setNewMessage] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Load chat history
    loadChatHistory()
    
    // Connect to WebSocket
    const ws = new WebSocket(import.meta.env.VITE_WS_URL)
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data)
      setMessages((prev) => [...prev, message])
    }

    return () => {
      ws.close()
    }
  }, [chatId])

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const loadChatHistory = async () => {
    try {
      const res = await fetch(`/api/chats/${chatId}/messages`)
      if (!res.ok) throw new Error('Failed to load messages')
      const data = await res.json()
      setMessages(data)
    } catch (error) {
      console.error('Error loading messages:', error)
    }
  }

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim()) return

    try {
      const res = await fetch(`/api/chats/${chatId}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content: newMessage }),
      })

      if (!res.ok) throw new Error('Failed to send message')
      setNewMessage('')
    } catch (error) {
      console.error('Error sending message:', error)
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${
              message.sender.id === user?.id ? 'justify-end' : 'justify-start'
            }`}
          >
            <div
              className={`max-w-[70%] rounded-lg p-3 ${
                message.sender.id === user?.id
                  ? 'bg-primary-600 text-white'
                  : 'bg-gray-100 text-gray-900'
              }`}
            >
              <div className="flex items-center space-x-2 mb-1">
                <img
                  src={message.sender.picture}
                  alt={message.sender.name}
                  className="h-6 w-6 rounded-full"
                />
                <span className="text-sm font-medium">
                  {message.sender.name}
                </span>
              </div>
              <p>{message.content}</p>
              <span className="text-xs opacity-75">
                {new Date(message.timestamp).toLocaleTimeString()}
              </span>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={handleSendMessage} className="p-4 border-t border-gray-200">
        <div className="flex space-x-4">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type a message..."
            className="input flex-1"
          />
          <button
            type="submit"
            className="btn btn-primary flex items-center space-x-2"
          >
            <span>Send</span>
            <PaperAirplaneIcon className="h-5 w-5" />
          </button>
        </div>
      </form>
    </div>
  )
} 