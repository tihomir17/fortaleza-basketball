import { useEffect, useState } from 'react'
import { useCalendarStore, type CalendarView } from '../store/calendarStore'
import { useTeamsStore } from '../store/teamsStore'
import { useAuthStore } from '../store/authStore'
import { useNavigate } from 'react-router-dom'
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  PlusIcon,
  TrophyIcon,
  AcademicCapIcon,
  UsersIcon,
  EyeIcon,
  WrenchScrewdriverIcon,
  TruckIcon,
  CalendarDaysIcon,
  ClockIcon
} from '@heroicons/react/24/outline'

// Helper function for date formatting
const toDateTimeStamp = (iso: string) => {
  const d = new Date(iso)
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
}

// Helper function for event permissions
const canCreateEvent = (user: any) => {
  if (!user) return false
  return user.role === 'COACH' || user.role === 'ADMIN' || 
         (user.role === 'STAFF' && user.staff_type === 'MANAGEMENT')
}

// Helper functions for event icons and colors
const getEventTypeIcon = (eventType: string) => {
  switch (eventType) {
    case 'GAME':
      return <TrophyIcon className="w-4 h-4" />
    case 'PRACTICE_TEAM':
    case 'PRACTICE_INDIVIDUAL':
      return <AcademicCapIcon className="w-4 h-4" />
    case 'TEAM_MEETING':
      return <UsersIcon className="w-4 h-4" />
    case 'SCOUTING_MEETING':
      return <EyeIcon className="w-4 h-4" />
    case 'STRENGTH_CONDITIONING':
      return <WrenchScrewdriverIcon className="w-4 h-4" />
    case 'TRAVEL_BUS':
    case 'TRAVEL_PLANE':
      return <TruckIcon className="w-4 h-4" />
    default:
      return <CalendarDaysIcon className="w-4 h-4" />
  }
}

const getEventTypeColor = (eventType: string) => {
  switch (eventType) {
    case 'GAME':
      return 'bg-red-100 text-red-800 border-red-200 dark:bg-red-900/30 dark:text-red-200 dark:border-red-800'
    case 'PRACTICE_TEAM':
    case 'PRACTICE_INDIVIDUAL':
      return 'bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-900/30 dark:text-blue-200 dark:border-blue-800'
    case 'TEAM_MEETING':
      return 'bg-green-100 text-green-800 border-green-200 dark:bg-green-900/30 dark:text-green-200 dark:border-green-800'
    case 'SCOUTING_MEETING':
      return 'bg-purple-100 text-purple-800 border-purple-200 dark:bg-purple-900/30 dark:text-purple-200 dark:border-purple-800'
    case 'STRENGTH_CONDITIONING':
      return 'bg-orange-100 text-orange-800 border-orange-200 dark:bg-orange-900/30 dark:text-orange-200 dark:border-orange-800'
    case 'TRAVEL_BUS':
    case 'TRAVEL_PLANE':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-200 dark:border-yellow-800'
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200 dark:bg-gray-900/30 dark:text-gray-200 dark:border-gray-800'
  }
}

const getGameIcon = () => {
  return <TrophyIcon className="w-4 h-4" />
}

const getGameColor = (isFinished: boolean) => {
  return isFinished 
    ? 'bg-green-100 text-green-800 border-green-200 dark:bg-green-900/30 dark:text-green-200 dark:border-green-800'
    : 'bg-red-100 text-red-800 border-red-200 dark:bg-red-900/30 dark:text-red-200 dark:border-red-800'
}

export default function Calendar() {
  const {
    events,
    games,
    currentDate,
    view,
    isLoading,
    error,
    setCurrentDate,
    setView,
    fetchEventsForMonth,
    fetchEventsForWeek,
    fetchEventsForDay,
    clearError
  } = useCalendarStore()

  const { teams, fetchTeams } = useTeamsStore()
  const { isAuthenticated, user } = useAuthStore()
  const navigate = useNavigate()
  const [selectedTeam, setSelectedTeam] = useState<number | undefined>()
  const [showMyTeamOnly, setShowMyTeamOnly] = useState(false)

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    }
  }, [isAuthenticated, navigate])

  // Fetch teams on component mount
  useEffect(() => {
    fetchTeams()
  }, [fetchTeams])

  // Get user's teams
  const getUserTeams = () => {
    if (!user) return []
    // This would need to be implemented in the backend to get user's teams
    // For now, we'll return all teams if user is a coach/staff
    if (user.role === 'COACH' || user.role === 'STAFF') {
      return teams
    }
    return []
  }

  const userTeams = getUserTeams()

  // Fetch calendar data when view or date changes (only if authenticated)
  useEffect(() => {
    if (!isAuthenticated) return
    
    const fetchData = async () => {
      // Determine which team to filter by
      let teamFilter = selectedTeam
      if (showMyTeamOnly && userTeams.length > 0) {
        // For now, use the first team the user is associated with
        // In a real implementation, this would be more sophisticated
        teamFilter = userTeams[0].id
      }
      
      if (view === 'month') {
        await fetchEventsForMonth(currentDate.getFullYear(), currentDate.getMonth(), teamFilter)
      } else if (view === 'week') {
        const weekStart = getWeekStart(currentDate)
        await fetchEventsForWeek(weekStart, teamFilter)
      } else if (view === 'day') {
        await fetchEventsForDay(currentDate, teamFilter)
      }
    }

    fetchData()
  }, [currentDate, view, selectedTeam, showMyTeamOnly, userTeams, isAuthenticated, fetchEventsForMonth, fetchEventsForWeek, fetchEventsForDay])

  // Helper functions
  const getWeekStart = (date: Date): Date => {
    const d = new Date(date)
    const day = d.getDay()
    const diff = d.getDate() - day
    return new Date(d.setDate(diff))
  }

  // Helper functions for future use
  // const getEventTypeIcon = (eventType: CalendarEvent['event_type']) => {
  //   switch (eventType) {
  //     case 'GAME':
  //       return <TrophyIcon className="w-4 h-4" />
  //     case 'PRACTICE_TEAM':
  //     case 'PRACTICE_INDIVIDUAL':
  //       return <AcademicCapIcon className="w-4 h-4" />
  //     case 'TEAM_MEETING':
  //       return <UsersIcon className="w-4 h-4" />
  //     case 'SCOUTING_MEETING':
  //       return <EyeIcon className="w-4 h-4" />
  //     case 'STRENGTH_CONDITIONING':
  //       return <WrenchScrewdriverIcon className="w-4 h-4" />
  //     case 'TRAVEL_BUS':
  //       return <TruckIcon className="w-4 h-4" />
  //     default:
  //       return <CalendarDaysIcon className="w-4 h-4" />
  //   }
  // }

  // const getEventTypeColor = (eventType: CalendarEvent['event_type']) => {
  //   switch (eventType) {
  //     case 'GAME':
  //       return 'bg-red-100 text-red-800 border-red-200'
  //     case 'PRACTICE_TEAM':
  //     case 'PRACTICE_INDIVIDUAL':
  //       return 'bg-blue-100 text-blue-800 border-blue-200'
  //     case 'TEAM_MEETING':
  //       return 'bg-green-100 text-green-800 border-green-200'
  //     case 'SCOUTING_MEETING':
  //       return 'bg-purple-100 text-purple-800 border-purple-200'
  //     case 'STRENGTH_CONDITIONING':
  //       return 'bg-orange-100 text-orange-800 border-orange-200'
  //     case 'TRAVEL_BUS':
  //     case 'TRAVEL_PLANE':
  //       return 'bg-yellow-100 text-yellow-800 border-yellow-200'
  //     default:
  //       return 'bg-gray-100 text-gray-800 border-gray-200'
  //   }
  // }

  // const formatTime = (dateTime: string) => {
  //   return new Date(dateTime).toLocaleTimeString('en-US', {
  //     hour: 'numeric',
  //     minute: '2-digit',
  //     hour12: true
  //   })
  // }

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  const navigateDate = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate)
    
    if (view === 'month') {
      newDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1))
    } else if (view === 'week') {
      newDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7))
    } else if (view === 'day') {
      newDate.setDate(currentDate.getDate() + (direction === 'next' ? 1 : -1))
    }
    
    setCurrentDate(newDate)
  }

  const goToToday = () => {
    setCurrentDate(new Date())
  }

  // Export functions

  const exportAllToICS = () => {
    const dtstamp = toDateTimeStamp(new Date().toISOString())
    const allItems = [...events, ...games.map(game => ({
      id: `game_${game.id}`,
      title: `${game.home_team.name} vs ${game.away_team.name}`,
      start_time: game.game_date,
      end_time: new Date(new Date(game.game_date).getTime() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours later
      description: `Game: ${game.home_team.name} vs ${game.away_team.name}`,
      event_type: 'GAME'
    }))]

    const icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Fortaleza Basketball//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      ...allItems.map(item => [
        'BEGIN:VEVENT',
        `UID:${item.id}@fortaleza`,
        `DTSTAMP:${dtstamp}`,
        `DTSTART:${toDateTimeStamp(item.start_time)}`,
        `DTEND:${toDateTimeStamp(item.end_time || item.start_time)}`,
        `SUMMARY:${(item.title || 'Event').replace(/\n/g, ' ')}`,
        `DESCRIPTION:${(item.description || '').replace(/\n/g, ' ')}`,
        'END:VEVENT'
      ].join('\r\n')),
      'END:VCALENDAR'
    ].join('\r\n')

    const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `fortaleza_calendar_${new Date().toISOString().slice(0, 10)}.ics`
    document.body.appendChild(a)
    a.click()
    a.remove()
    URL.revokeObjectURL(url)
  }


  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Calendar</h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Manage your team's schedule and events
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          {canCreateEvent(user) && (
            <button 
              onClick={() => navigate('/events')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <PlusIcon className="w-4 h-4 mr-2" />
              Add Event
            </button>
          )}
          <button 
            onClick={() => exportAllToICS()}
            className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Export All
          </button>
        </div>
      </div>

      {/* Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0">
        <div className="flex items-center space-x-4">
          {/* View Toggle */}
          <div className="flex rounded-lg border border-gray-200 dark:border-gray-700">
            {(['month', 'week', 'day'] as CalendarView[]).map((viewType) => (
              <button
                key={viewType}
                onClick={() => setView(viewType)}
                className={`px-3 py-2 text-sm font-medium capitalize transition-colors ${
                  view === viewType
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                } ${viewType === 'month' ? 'rounded-l-lg' : viewType === 'day' ? 'rounded-r-lg' : ''}`}
              >
                {viewType}
              </button>
            ))}
          </div>
          
          {/* Team Filter */}
          <select
            value={selectedTeam || ''}
            onChange={(e) => {
              if (e.target.value === 'my-team') {
                setShowMyTeamOnly(true)
                setSelectedTeam(undefined)
              } else {
                setShowMyTeamOnly(false)
                setSelectedTeam(e.target.value ? parseInt(e.target.value) : undefined)
              }
            }}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
          >
            <option value="">All Teams</option>
            {userTeams.length > 0 && <option value="my-team">My Team</option>}
            {teams.map(team => (
              <option key={team.id} value={team.id}>{team.name}</option>
            ))}
          </select>
        </div>
        
        <div className="flex items-center space-x-2">
          {/* Navigation */}
          <button
            onClick={() => navigateDate('prev')}
            className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <ChevronLeftIcon className="w-5 h-5" />
          </button>
          
          <button
            onClick={goToToday}
            className="px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            Today
          </button>
          
          <button
            onClick={() => navigateDate('next')}
            className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <ChevronRightIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="text-red-400">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
              </div>
            </div>
            <button
              onClick={clearError}
              className="text-red-400 hover:text-red-600 dark:hover:text-red-300"
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span className="ml-2 text-gray-600 dark:text-gray-400">Loading calendar...</span>
        </div>
      )}

      {/* Calendar Content */}
      {!isLoading && (
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          {view === 'month' && (
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-6">
                {currentDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
              </h2>
              <CalendarGrid 
                currentDate={currentDate}
                events={events}
                games={games}
                onDateClick={(date) => setCurrentDate(date)}
                onEventClick={() => navigate(`/events`)}
                onGameClick={(game) => navigate(`/game-tracking/${game.id}`)}
              />
            </div>
          )}
          
          {view === 'week' && (
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-6">
                Week View
              </h2>
              <WeekView 
                currentDate={currentDate}
                events={events}
                games={games}
                onEventClick={() => navigate(`/events`)}
                onGameClick={(game) => navigate(`/game-tracking/${game.id}`)}
              />
            </div>
          )}
          
          {view === 'day' && (
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-6">
                {formatDate(currentDate)}
              </h2>
              <DayView 
                currentDate={currentDate}
                events={events}
                games={games}
                onEventClick={() => navigate(`/events`)}
                onGameClick={(game) => navigate(`/game-tracking/${game.id}`)}
              />
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// Calendar Grid Component
function CalendarGrid({ 
  currentDate, 
  events, 
  games, 
  onDateClick, 
  onEventClick, 
  onGameClick 
}: {
  currentDate: Date
  events: any[]
  games: any[]
  onDateClick: (date: Date) => void
  onEventClick: (event: any) => void
  onGameClick: (game: any) => void
}) {
  const startOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
  // const endOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)
  const startOfCalendar = new Date(startOfMonth)
  startOfCalendar.setDate(startOfCalendar.getDate() - startOfMonth.getDay())
  
  const days = []
  const current = new Date(startOfCalendar)
  
  // Generate 42 days (6 weeks)
  for (let i = 0; i < 42; i++) {
    days.push(new Date(current))
    current.setDate(current.getDate() + 1)
  }
  
  const getEventsForDay = (date: Date) => {
    const dayEvents = events.filter(event => 
      new Date(event.start_time).toDateString() === date.toDateString()
    )
    const dayGames = games.filter(game => 
      new Date(game.game_date).toDateString() === date.toDateString()
    )
    return [...dayEvents, ...dayGames]
  }
  
  const isToday = (date: Date) => {
    const today = new Date()
    return date.toDateString() === today.toDateString()
  }
  
  const isCurrentMonth = (date: Date) => {
    return date.getMonth() === currentDate.getMonth()
  }
  
  return (
    <div className="grid grid-cols-7 gap-px bg-gray-200 dark:bg-gray-600 rounded-lg overflow-hidden">
      {/* Header */}
      {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
        <div key={day} className="bg-gray-100 dark:bg-gray-700 p-2 text-center text-sm font-medium text-gray-700 dark:text-gray-300">
          {day}
        </div>
      ))}
      
      {/* Days */}
      {days.map((date, index) => {
        const dayEvents = getEventsForDay(date)
        const isCurrentMonthDay = isCurrentMonth(date)
        const isTodayDay = isToday(date)
        
        return (
          <div
            key={index}
            className={`bg-white dark:bg-gray-800 p-2 min-h-[100px] border-r border-b border-gray-200 dark:border-gray-600 ${
              !isCurrentMonthDay ? 'text-gray-400 dark:text-gray-500' : ''
            } ${isTodayDay ? 'bg-blue-50 dark:bg-blue-900/20' : ''}`}
            onClick={() => onDateClick(date)}
          >
            <div className={`text-sm font-medium mb-1 ${isTodayDay ? 'text-blue-600 dark:text-blue-400' : ''}`}>
              {date.getDate()}
            </div>
            
            {/* Event markers */}
            <div className="space-y-1">
              {dayEvents.slice(0, 3).map((item, idx) => {
                const isGame = 'home_team' in item
                const isFinished = isGame && item.home_team_score !== null && item.away_team_score !== null
                
                return (
                  <div
                    key={idx}
                    className={`text-xs p-1 rounded cursor-pointer truncate flex items-center gap-1 ${
                      isGame 
                        ? getGameColor(isFinished)
                        : getEventTypeColor(item.event_type)
                    }`}
                    onClick={(e) => {
                      e.stopPropagation()
                      if (isGame) {
                        onGameClick(item)
                      } else {
                        onEventClick(item)
                      }
                    }}
                  >
                    {isGame ? (
                      getGameIcon()
                    ) : (
                      getEventTypeIcon(item.event_type)
                    )}
                    <span className="truncate">
                      {isGame ? (
                        isFinished ? (
                          `${item.home_team.name} ${item.home_team_score}-${item.away_team_score} ${item.away_team.name}`
                        ) : (
                          `${item.home_team.name} vs ${item.away_team.name}`
                        )
                      ) : (
                        item.title
                      )}
                    </span>
                  </div>
                )
              })}
              {dayEvents.length > 3 && (
                <div className="text-xs text-gray-500 dark:text-gray-400">
                  +{dayEvents.length - 3} more
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// Week View Component
function WeekView({ 
  currentDate, 
  events, 
  games, 
  onEventClick, 
  onGameClick 
}: {
  currentDate: Date
  events: any[]
  games: any[]
  onEventClick: (event: any) => void
  onGameClick: (game: any) => void
}) {
  const weekStart = new Date(currentDate)
  weekStart.setDate(currentDate.getDate() - currentDate.getDay())
  
  const weekDays = []
  for (let i = 0; i < 7; i++) {
    const day = new Date(weekStart)
    day.setDate(weekStart.getDate() + i)
    weekDays.push(day)
  }
  
  const getEventsForDay = (date: Date) => {
    const dayEvents = events.filter(event => 
      new Date(event.start_time).toDateString() === date.toDateString()
    )
    const dayGames = games.filter(game => 
      new Date(game.game_date).toDateString() === date.toDateString()
    )
    return [...dayEvents, ...dayGames].sort((a, b) => {
      const timeA = 'start_time' in a ? new Date(a.start_time) : new Date(a.game_date)
      const timeB = 'start_time' in b ? new Date(b.start_time) : new Date(b.game_date)
      return timeA.getTime() - timeB.getTime()
    })
  }
  
  return (
    <div className="grid grid-cols-7 gap-4">
      {weekDays.map((day, index) => {
        const dayEvents = getEventsForDay(day)
        const isToday = day.toDateString() === new Date().toDateString()
        
        return (
          <div key={index} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <div className={`text-center mb-4 ${isToday ? 'text-blue-600 dark:text-blue-400 font-bold' : ''}`}>
              <div className="text-sm text-gray-500 dark:text-gray-400">
                {day.toLocaleDateString('en-US', { weekday: 'short' })}
              </div>
              <div className="text-lg font-medium">
                {day.getDate()}
              </div>
            </div>
            
            <div className="space-y-2">
              {dayEvents.map((item, idx) => {
                const isGame = 'home_team' in item
                const isFinished = isGame && item.home_team_score !== null && item.away_team_score !== null
                
                return (
                  <div
                    key={idx}
                    className={`p-2 rounded cursor-pointer text-sm ${
                      isGame 
                        ? getGameColor(isFinished)
                        : getEventTypeColor(item.event_type)
                    }`}
                    onClick={() => {
                      if (isGame) {
                        onGameClick(item)
                      } else {
                        onEventClick(item)
                      }
                    }}
                  >
                    <div className="flex items-center gap-2">
                      {isGame ? (
                        getGameIcon()
                      ) : (
                        getEventTypeIcon(item.event_type)
                      )}
                      <div className="font-medium flex-1">
                        {isGame ? (
                          isFinished ? (
                            `${item.home_team.name} ${item.home_team_score}-${item.away_team_score} ${item.away_team.name}`
                          ) : (
                            `${item.home_team.name} vs ${item.away_team.name}`
                          )
                        ) : (
                          item.title
                        )}
                      </div>
                    </div>
                    <div className="text-xs opacity-75 flex items-center gap-1 mt-1">
                      <ClockIcon className="w-3 h-3" />
                      {isGame ? (
                        new Date(item.game_date).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
                      ) : (
                        new Date(item.start_time).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// Day View Component
function DayView({ 
  currentDate, 
  events, 
  games, 
  onEventClick, 
  onGameClick 
}: {
  currentDate: Date
  events: any[]
  games: any[]
  onEventClick: (event: any) => void
  onGameClick: (game: any) => void
}) {
  const dayEvents = events.filter(event => 
    new Date(event.start_time).toDateString() === currentDate.toDateString()
  )
  const dayGames = games.filter(game => 
    new Date(game.game_date).toDateString() === currentDate.toDateString()
  )
  
  const allItems = [...dayEvents, ...dayGames].sort((a, b) => {
    const timeA = 'start_time' in a ? new Date(a.start_time) : new Date(a.game_date)
    const timeB = 'start_time' in b ? new Date(b.start_time) : new Date(b.game_date)
    return timeA.getTime() - timeB.getTime()
  })
  
  return (
    <div className="space-y-4">
      {allItems.length === 0 ? (
        <div className="text-center text-gray-500 dark:text-gray-400 py-8">
          No events scheduled for this day
        </div>
      ) : (
        allItems.map((item, index) => {
          const isGame = 'home_team' in item
          const isFinished = isGame && item.home_team_score !== null && item.away_team_score !== null
          const isFuture = (isGame ? new Date(item.game_date) : new Date(item.start_time)) > new Date()
          
          return (
            <div
              key={index}
              className={`p-4 rounded-lg border cursor-pointer ${
                isGame 
                  ? isFinished 
                    ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800'
                    : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
                  : 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800'
              }`}
              onClick={() => {
                if (isGame) {
                  onGameClick(item)
                } else {
                  onEventClick(item)
                }
              }}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    {isGame ? (
                      getGameIcon()
                    ) : (
                      getEventTypeIcon(item.event_type)
                    )}
                    <div className="font-medium text-lg">
                      {isGame ? (
                        isFinished ? (
                          `${item.home_team.name} ${item.home_team_score}-${item.away_team_score} ${item.away_team.name}`
                        ) : (
                          `${item.home_team.name} vs ${item.away_team.name}`
                        )
                      ) : (
                        item.title
                      )}
                    </div>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400 flex items-center gap-1">
                    <ClockIcon className="w-4 h-4" />
                    {isGame ? (
                      new Date(item.game_date).toLocaleString('en-US', { 
                        hour: 'numeric', 
                        minute: '2-digit',
                        hour12: true 
                      })
                    ) : (
                      new Date(item.start_time).toLocaleString('en-US', { 
                        hour: 'numeric', 
                        minute: '2-digit',
                        hour12: true 
                      })
                    )}
                  </div>
                  {!isGame && item.description && (
                    <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      {item.description}
                    </div>
                  )}
                </div>
                
                {/* Export options for future events only */}
                {isFuture && (
                  <div className="flex gap-2">
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        // Export to ICS
                        const dtstamp = toDateTimeStamp(new Date().toISOString())
                        const dtstart = isGame ? toDateTimeStamp(item.game_date) : toDateTimeStamp(item.start_time)
                        const dtend = isGame ? 
                          toDateTimeStamp(new Date(new Date(item.game_date).getTime() + 2 * 60 * 60 * 1000).toISOString()) :
                          toDateTimeStamp(item.end_time || item.start_time)
                        const uid = isGame ? `game-${item.id}@fortaleza` : `event-${item.id}@fortaleza`
                        
                        const ics = [
                          'BEGIN:VCALENDAR',
                          'VERSION:2.0',
                          'PRODID:-//Fortaleza Basketball//EN',
                          'CALSCALE:GREGORIAN',
                          'METHOD:PUBLISH',
                          'BEGIN:VEVENT',
                          `UID:${uid}`,
                          `DTSTAMP:${dtstamp}`,
                          `DTSTART:${dtstart}`,
                          `DTEND:${dtend}`,
                          `SUMMARY:${isGame ? `${item.home_team.name} vs ${item.away_team.name}` : item.title}`,
                          `DESCRIPTION:${isGame ? `Game: ${item.home_team.name} vs ${item.away_team.name}` : (item.description || '')}`,
                          'END:VEVENT',
                          'END:VCALENDAR',
                        ].join('\r\n')

                        const blob = new Blob([ics], { type: 'text/calendar;charset=utf-8' })
                        const url = URL.createObjectURL(blob)
                        const a = document.createElement('a')
                        a.href = url
                        a.download = `${isGame ? `${item.home_team.name}_vs_${item.away_team.name}` : item.title.replace(/\s+/g, '_')}.ics`
                        document.body.appendChild(a)
                        a.click()
                        a.remove()
                        URL.revokeObjectURL(url)
                      }}
                      className="px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                    >
                      Export
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        // Gmail integration
                        const subject = isGame ? 
                          `Game: ${item.home_team.name} vs ${item.away_team.name}` :
                          `Event: ${item.title}`
                        const body = isGame ?
                          `Game: ${item.home_team.name} vs ${item.away_team.name}\nDate: ${new Date(item.game_date).toLocaleString()}` :
                          `Event: ${item.title}\nDate: ${new Date(item.start_time).toLocaleString()}\nDescription: ${item.description || 'No description'}`
                        window.open(`mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`)
                      }}
                      className="px-3 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                    >
                      Gmail
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        // Google Calendar integration
                        const start = isGame ? new Date(item.game_date) : new Date(item.start_time)
                        const end = isGame ? 
                          new Date(new Date(item.game_date).getTime() + 2 * 60 * 60 * 1000) :
                          new Date(item.end_time || item.start_time)
                        
                        const startStr = start.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
                        const endStr = end.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
                        
                        const title = isGame ? `${item.home_team.name} vs ${item.away_team.name}` : item.title
                        const details = isGame ? `Game: ${item.home_team.name} vs ${item.away_team.name}` : (item.description || '')
                        
                        const googleUrl = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(title)}&dates=${startStr}/${endStr}&details=${encodeURIComponent(details)}`
                        window.open(googleUrl, '_blank')
                      }}
                      className="px-3 py-1 text-xs bg-purple-600 text-white rounded hover:bg-purple-700"
                    >
                      Google
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        // Outlook Calendar integration
                        const start = isGame ? new Date(item.game_date) : new Date(item.start_time)
                        const end = isGame ? 
                          new Date(new Date(item.game_date).getTime() + 2 * 60 * 60 * 1000) :
                          new Date(item.end_time || item.start_time)
                        
                        const title = isGame ? `${item.home_team.name} vs ${item.away_team.name}` : item.title
                        const details = isGame ? `Game: ${item.home_team.name} vs ${item.away_team.name}` : (item.description || '')
                        
                        const outlookUrl = `https://outlook.live.com/calendar/0/deeplink/compose?path=/calendar/action/compose&rru=addevent&startdt=${start.toISOString()}&enddt=${end.toISOString()}&subject=${encodeURIComponent(title)}&body=${encodeURIComponent(details)}`
                        window.open(outlookUrl, '_blank')
                      }}
                      className="px-3 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700"
                    >
                      Outlook
                    </button>
                  </div>
                )}
              </div>
            </div>
          )
        })
      )}
    </div>
  )
}