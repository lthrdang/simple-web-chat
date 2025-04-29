import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

declare global {
  interface Window {
    google: {
      accounts: {
        id: {
          initialize: (config: any) => void
          renderButton: (element: HTMLElement, config: any) => void
        }
      }
    }
  }
}

export default function Login() {
  const navigate = useNavigate()
  const { isAuthenticated, setUser, setToken } = useAuth()

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/chat')
    }

    // Initialize Google Sign-In
    window.google.accounts.id.initialize({
      client_id: import.meta.env.VITE_GOOGLE_CLIENT_ID,
      callback: handleGoogleSignIn,
      auto_select: false,
      cancel_on_tap_outside: true,
      context: 'signin',
      ux_mode: 'popup',
      prompt_parent_id: 'googleSignIn',
    })

    // Render Google Sign-In button
    window.google.accounts.id.renderButton(
      document.getElementById('googleSignIn')!,
      { 
        theme: 'outline', 
        size: 'large',
        width: 250,
        text: 'signin_with',
        shape: 'rectangular',
        logo_alignment: 'center',
      }
    )
  }, [isAuthenticated, navigate])

  const handleGoogleSignIn = async (response: any) => {
    try {
      // Send the token to your backend
      const res = await fetch('/api/auth/google', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ token: response.credential }),
      })

      if (!res.ok) {
        throw new Error('Authentication failed')
      }

      const data = await res.json()
      
      // Update authentication state
      setUser(data.user)
      setToken(data.token)
      
      // Navigate to chat page
      navigate('/chat')
    } catch (error) {
      console.error('Authentication error:', error)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
        </div>
        <div className="mt-8 space-y-6">
          <div id="googleSignIn" className="flex justify-center"></div>
        </div>
      </div>
    </div>
  )
} 