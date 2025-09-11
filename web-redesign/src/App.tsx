import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Suspense, lazy, useEffect } from 'react'
import { Layout } from './components/layout/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { PageLoader } from './components/ui/PageLoader'
import { BackendStatus } from './components/BackendStatus'
import { ToastContainer } from './components/ui/NotificationSystem'
import { registerServiceWorker, setupOfflineDetection, showInstallPrompt } from './utils/serviceWorker'
import { Login } from './pages/Login'

// Lazy load pages for better performance
const Dashboard = lazy(() => import('./pages/Dashboard').then(module => ({ default: module.Dashboard })))
const Games = lazy(() => import('./pages/Games').then(module => ({ default: module.Games })))
const Teams = lazy(() => import('./pages/Teams'))
const LiveTracking = lazy(() => import('./pages/LiveTracking').then(module => ({ default: module.LiveTracking })))
const Analytics = lazy(() => import('./pages/Analytics'))
const Scouting = lazy(() => import('./pages/Scouting').then(module => ({ default: module.Scouting })))
const UserManagement = lazy(() => import('./pages/UserManagement').then(module => ({ default: module.UserManagement })))

// New route placeholders mapped from Flutter app
const GameDetails = lazy(() => import('./pages/games/GameDetails').then(m => ({ default: m.GameDetails })))
const GameStats = lazy(() => import('./pages/games/GameStats').then(m => ({ default: m.GameStats })))
const GamePlayerStats = lazy(() => import('./pages/games/GamePlayerStats').then(m => ({ default: m.GamePlayerStats })))
const GameTrack = lazy(() => import('./pages/games/GameTrack').then(m => ({ default: m.GameTrack })))
const GamePostReport = lazy(() => import('./pages/games/GamePostReport').then(m => ({ default: m.GamePostReport })))
const GameAdvancedReport = lazy(() => import('./pages/games/GameAdvancedReport').then(m => ({ default: m.GameAdvancedReport })))
const GameAddPossession = lazy(() => import('./pages/games/GameAddPossession').then(m => ({ default: m.GameAddPossession })))
const GameSchedule = lazy(() => import('./pages/games/GameSchedule').then(m => ({ default: m.GameSchedule })))

const TeamDetails = lazy(() => import('./pages/teams/TeamDetails').then(m => ({ default: m.TeamDetails })))
const TeamPlayCategories = lazy(() => import('./pages/teams/TeamPlayCategories').then(m => ({ default: m.TeamPlayCategories })))
const Roster = lazy(() => import('./pages/teams/Roster').then(m => ({ default: m.Roster })))

const Playbook = lazy(() => import('./pages/Playbook').then(m => ({ default: m.Playbook })))
const Calendar = lazy(() => import('./pages/Calendar').then(m => ({ default: m.Calendar })))
const Events = lazy(() => import('./pages/Events').then(m => ({ default: m.Events })))
const EventAdd = lazy(() => import('./pages/EventAdd').then(m => ({ default: m.EventAdd })))
const ScoutingReports = lazy(() => import('./pages/ScoutingReports').then(m => ({ default: m.ScoutingReports })))
const OpponentScouting = lazy(() => import('./pages/OpponentScouting').then(m => ({ default: m.OpponentScouting })))
const SelfScouting = lazy(() => import('./pages/SelfScouting').then(m => ({ default: m.SelfScouting })))
const CoachSelfScouting = lazy(() => import('./pages/CoachSelfScouting').then(m => ({ default: m.CoachSelfScouting })))
const PlayerHealth = lazy(() => import('./pages/PlayerHealth').then(m => ({ default: m.PlayerHealth })))
const InjuryReports = lazy(() => import('./pages/InjuryReports').then(m => ({ default: m.InjuryReports })))
const TrainingPrograms = lazy(() => import('./pages/TrainingPrograms').then(m => ({ default: m.TrainingPrograms })))
const PerformanceMetrics = lazy(() => import('./pages/PerformanceMetrics').then(m => ({ default: m.PerformanceMetrics })))
const IndividualGamePrep = lazy(() => import('./pages/IndividualGamePrep').then(m => ({ default: m.IndividualGamePrep })))
const IndividualPostGame = lazy(() => import('./pages/IndividualPostGame').then(m => ({ default: m.IndividualPostGame })))
const ChangePassword = lazy(() => import('./pages/ChangePassword').then(m => ({ default: m.ChangePassword })))
const Debug = lazy(() => import('./pages/Debug').then(m => ({ default: m.Debug })))

function App() {
  useEffect(() => {
    if (import.meta.env.PROD) {
      // Register SW only in production
      registerServiceWorker()
      setupOfflineDetection()
      showInstallPrompt()
    } else {
      // In development, aggressively remove any existing SWs to avoid stale caching/redirects
      if (typeof navigator !== 'undefined' && 'serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(registrations => {
          for (const registration of registrations) {
            registration.unregister().catch(() => {})
          }
        })
      }
    }
  }, [])

  return (
    <Router>
      <BackendStatus />
      <ToastContainer />
      <Suspense fallback={<PageLoader />}>
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<Login />} />

          {/* Protected routes */}
          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <Layout>
                  <Routes>
                    <Route path="/" element={<Dashboard />} />
                    <Route path="/games" element={<Games />} />
                    <Route path="/games/add" element={<GameSchedule />} />
                    <Route path="/games/:gameId" element={<GameDetails />} />
                    <Route path="/games/:gameId/stats" element={<GameStats />} />
                    <Route path="/games/:gameId/player-stats" element={<GamePlayerStats />} />
                    <Route path="/games/:gameId/track" element={<GameTrack />} />
                    <Route path="/games/:gameId/post-game-report" element={<GamePostReport />} />
                    <Route path="/games/:gameId/advanced-report" element={<GameAdvancedReport />} />
                    <Route path="/games/:gameId/add-possession" element={<GameAddPossession />} />
                    <Route path="/teams" element={<Teams />} />
                    <Route path="/teams/roster" element={<Roster />} />
                    <Route path="/teams/:teamId" element={<TeamDetails />} />
                    <Route path="/teams/:teamId/play-categories" element={<TeamPlayCategories />} />
                    <Route path="/live" element={<LiveTracking />} />
                    <Route path="/analytics" element={<Analytics />} />
                    <Route path="/scouting" element={<Scouting />} />
                    <Route path="/playbook" element={<Playbook />} />
                    <Route path="/calendar" element={<Calendar />} />
                    <Route path="/events" element={<Events />} />
                    <Route path="/events/add" element={<EventAdd />} />
                    <Route path="/scouting-reports" element={<ScoutingReports />} />
                    <Route path="/opponent-scouting" element={<OpponentScouting />} />
                    <Route path="/self-scouting" element={<SelfScouting />} />
                    <Route path="/coach-self-scouting" element={<CoachSelfScouting />} />
                    <Route path="/player-health" element={<PlayerHealth />} />
                    <Route path="/injury-reports" element={<InjuryReports />} />
                    <Route path="/training-programs" element={<TrainingPrograms />} />
                    <Route path="/performance-metrics" element={<PerformanceMetrics />} />
                    <Route path="/individual-game-prep" element={<IndividualGamePrep />} />
                    <Route path="/individual-post-game" element={<IndividualPostGame />} />
                    <Route path="/change-password" element={<ChangePassword />} />
                    <Route path="/debug" element={<Debug />} />
                    <Route path="/users" element={<UserManagement />} />
                    {/* Fallback to home */}
                    <Route path="*" element={<Navigate to="/" replace />} />
                  </Routes>
                </Layout>
              </ProtectedRoute>
            }
          />
        </Routes>
      </Suspense>
    </Router>
  )
}

export default App