import { Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import Navbar from './Navbar'
import Sidebar from './Sidebar'

export default function Layout() {
  const { user } = useAuth()

  return (
    <div className="min-h-screen bg-gray-100">
      <Navbar />
      <div className="flex h-[calc(100vh-64px)]">
        <Sidebar />
        <main className="flex-1 p-4 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  )
} 