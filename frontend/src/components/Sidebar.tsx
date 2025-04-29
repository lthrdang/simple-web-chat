import { useState, useEffect, useCallback } from 'react'
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline'
import { useAuth } from '../hooks/useAuth'
import { debounce } from 'lodash'

interface Chat {
  id: string
  name: string
  lastMessage: string
  unreadCount: number
  isGroup: boolean
  picture?: string
  email?: string
}

export default function Sidebar() {
  const { user } = useAuth()
  const [searchQuery, setSearchQuery] = useState('')
  const [chats, setChats] = useState<Chat[]>([])
  const [isSearching, setIsSearching] = useState(false)

  useEffect(() => {
    loadChats()
  }, [])

  const loadChats = async () => {
    try {
      const res = await fetch('/api/chats')
      if (!res.ok) throw new Error('Failed to load chats')
      const data = await res.json()
      setChats(data)
    } catch (error) {
      console.error('Error loading chats:', error)
    }
  }

  // Debounced search function
  const debouncedSearch = useCallback(
    debounce(async (query: string) => {
      if (!query.trim()) {
        loadChats()
        return
      }

      setIsSearching(true)
      try {
        const res = await fetch(`/api/users/search?q=${encodeURIComponent(query)}`)
        if (!res.ok) throw new Error('Search failed')
        const data = await res.json()
        setChats(data)
      } catch (error) {
        console.error('Error searching users:', error)
        setChats([])
      } finally {
        setIsSearching(false)
      }
    }, 300),
    []
  )

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault()
    debouncedSearch(searchQuery)
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setSearchQuery(value)
    if (value.trim()) {
      debouncedSearch(value)
    } else {
      loadChats()
    }
  }

  return (
    <div className="w-80 bg-white border-r border-gray-200">
      <div className="p-4">
        <form onSubmit={handleSearch} className="relative">
          <input
            type="text"
            placeholder="Search users..."
            className="input pl-10"
            value={searchQuery}
            onChange={handleInputChange}
          />
          <button
            type="submit"
            className="absolute right-3 top-1/2 transform -translate-y-1/2"
            disabled={isSearching}
          >
            <MagnifyingGlassIcon className={`h-5 w-5 ${isSearching ? 'text-gray-300' : 'text-gray-400 hover:text-gray-600'}`} />
          </button>
        </form>
      </div>

      <div className="overflow-y-auto h-[calc(100vh-64px-73px)]">
        {isSearching ? (
          <div className="p-4 text-center text-gray-500">Searching...</div>
        ) : chats.length === 0 ? (
          <div className="p-4 text-center text-gray-500">No results found</div>
        ) : (
          chats.map((chat) => (
            <div
              key={chat.id}
              className="p-4 hover:bg-gray-50 cursor-pointer border-b border-gray-100"
            >
              <div className="flex items-center space-x-3">
                <div className="flex-shrink-0">
                  <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                    {chat.isGroup ? (
                      <span className="text-sm font-medium text-gray-600">
                        {chat.name.charAt(0)}
                      </span>
                    ) : (
                      <img
                        src={chat.picture}
                        alt={chat.name}
                        className="h-10 w-10 rounded-full"
                      />
                    )}
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {chat.name}
                  </p>
                  {chat.email && (
                    <p className="text-xs text-gray-500 truncate">
                      {chat.email}
                    </p>
                  )}
                </div>
                {chat.unreadCount > 0 && (
                  <div className="flex-shrink-0">
                    <span className="inline-flex items-center justify-center h-5 w-5 rounded-full bg-primary-600 text-xs font-medium text-white">
                      {chat.unreadCount}
                    </span>
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
} 