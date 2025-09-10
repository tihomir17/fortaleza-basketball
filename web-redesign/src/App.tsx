import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { Suspense, lazy, useEffect } from 'react'
import { Layout } from './components/layout/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { PageLoader } from './components/ui/PageLoader'
import { registerServiceWorker, setupOfflineDetection, showInstallPrompt } from './utils/serviceWorker'

// Lazy load pages for better performance
const Dashboard = lazy(() => import('./pages/Dashboard').then(module => ({ default: module.Dashboard })))
const Games = lazy(() => import('./pages/Games').then(module => ({ default: module.Games })))
const Teams = lazy(() => import('./pages/Teams').then(module => ({ default: module.Teams })))
const LiveTracking = lazy(() => import('./pages/LiveTracking').then(module => ({ default: module.LiveTracking })))
const Analytics = lazy(() => import('./pages/Analytics').then(module => ({ default: module.Analytics })))
const Scouting = lazy(() => import('./pages/Scouting').then(module => ({ default: module.Scouting })))
const UserManagement = lazy(() => import('./pages/UserManagement').then(module => ({ default: module.UserManagement })))

function App() {
  useEffect(() => {
    // Register service worker for PWA functionality
    registerServiceWorker()
    
    // Setup offline detection
    setupOfflineDetection()
    
    // Show PWA install prompt
    showInstallPrompt()
  }, [])

  return (
    <Router>
      <ProtectedRoute>
        <Layout>
          <Suspense fallback={<PageLoader />}>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/games" element={<Games />} />
              <Route path="/teams" element={<Teams />} />
              <Route path="/live" element={<LiveTracking />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/scouting" element={<Scouting />} />
              <Route path="/users" element={<UserManagement />} />
            </Routes>
          </Suspense>
        </Layout>
      </ProtectedRoute>
    </Router>
  )
}

export default App