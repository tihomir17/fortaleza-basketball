import { create } from 'zustand'
import { calendarService, type CalendarEvent, type CalendarEventCreate, type GameEvent } from '../services/calendar'

export type CalendarView = 'month' | 'week' | 'day'

interface CalendarState {
  // Data
  events: CalendarEvent[]
  games: GameEvent[]
  currentDate: Date
  view: CalendarView
  selectedDate: Date | null
  selectedEvent: CalendarEvent | null
  
  // Loading states
  isLoading: boolean
  error: string | null
  
  // Actions
  setCurrentDate: (date: Date) => void
  setView: (view: CalendarView) => void
  setSelectedDate: (date: Date | null) => void
  setSelectedEvent: (event: CalendarEvent | null) => void
  
  // Data fetching
  fetchEvents: (params?: {
    team?: number
    event_type?: string
    start_time__gte?: string
    start_time__lte?: string
    end_time__gte?: string
    end_time__lte?: string
  }) => Promise<void>
  
  fetchGames: (params?: {
    home_team?: number
    away_team?: number
    game_date__gte?: string
    game_date__lte?: string
  }) => Promise<void>
  fetchCalendarData: (params?: {
    team?: number
    event_type?: string
    start_time__gte?: string
    start_time__lte?: string
    end_time__gte?: string
    end_time__lte?: string
  }) => Promise<void>
  
  // Event management
  createEvent: (eventData: CalendarEventCreate) => Promise<CalendarEvent>
  updateEvent: (id: number, eventData: Partial<CalendarEventCreate>) => Promise<CalendarEvent>
  deleteEvent: (id: number) => Promise<void>
  
  // Date range helpers
  fetchEventsForMonth: (year: number, month: number, teamId?: number) => Promise<void>
  fetchEventsForWeek: (startDate: Date, teamId?: number) => Promise<void>
  fetchEventsForDay: (date: Date, teamId?: number) => Promise<void>
  
  // Utility
  clearError: () => void
  getEventsForDate: (date: Date) => CalendarEvent[]
  getGamesForDate: (date: Date) => GameEvent[]
  getAllItemsForDate: (date: Date) => (CalendarEvent | GameEvent)[]
}

export const useCalendarStore = create<CalendarState>((set, get) => ({
  // Initial state
  events: [],
  games: [],
  currentDate: new Date(),
  view: 'month',
  selectedDate: null,
  selectedEvent: null,
  isLoading: false,
  error: null,

  // Basic setters
  setCurrentDate: (date: Date) => set({ currentDate: date }),
  setView: (view: CalendarView) => set({ view }),
  setSelectedDate: (date: Date | null) => set({ selectedDate: date }),
  setSelectedEvent: (event: CalendarEvent | null) => set({ selectedEvent: event }),

  // Data fetching
  fetchEvents: async (params) => {
    set({ isLoading: true, error: null })
    try {
      const events = await calendarService.getEvents(params)
      set({ events, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch events',
        isLoading: false 
      })
    }
  },

  fetchGames: async (params) => {
    set({ isLoading: true, error: null })
    try {
      const games = await calendarService.getGames(params)
      set({ games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch games',
        isLoading: false 
      })
    }
  },

  fetchCalendarData: async (params) => {
    set({ isLoading: true, error: null })
    try {
      const { events, games } = await calendarService.getCalendarData(params)
      set({ events, games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch calendar data',
        isLoading: false 
      })
    }
  },

  // Event management
  createEvent: async (eventData: CalendarEventCreate) => {
    set({ isLoading: true, error: null })
    try {
      const newEvent = await calendarService.createEvent(eventData)
      set(state => ({ 
        events: [...state.events, newEvent],
        isLoading: false 
      }))
      return newEvent
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to create event',
        isLoading: false 
      })
      throw error
    }
  },

  updateEvent: async (id: number, eventData: Partial<CalendarEventCreate>) => {
    set({ isLoading: true, error: null })
    try {
      const updatedEvent = await calendarService.updateEvent(id, eventData)
      set(state => ({
        events: state.events.map(event => 
          event.id === id ? updatedEvent : event
        ),
        isLoading: false
      }))
      return updatedEvent
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to update event',
        isLoading: false 
      })
      throw error
    }
  },

  deleteEvent: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      await calendarService.deleteEvent(id)
      set(state => ({
        events: state.events.filter(event => event.id !== id),
        isLoading: false
      }))
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to delete event',
        isLoading: false 
      })
      throw error
    }
  },

  // Date range helpers
  fetchEventsForMonth: async (year: number, month: number, teamId?: number) => {
    set({ isLoading: true, error: null })
    try {
      // Calculate date range for the month
      const startDate = new Date(year, month, 1)
      const endDate = new Date(year, month + 1, 0)
      
      // Prepare game filters
      const gameParams = teamId ? {
        home_team: teamId,
        away_team: teamId,
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      } : {
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      }

      const [events, games] = await Promise.all([
        calendarService.getEventsForMonth(year, month, teamId),
        calendarService.getGames(gameParams)
      ])
      set({ events, games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch events for month',
        isLoading: false 
      })
    }
  },

  fetchEventsForWeek: async (startDate: Date, teamId?: number) => {
    set({ isLoading: true, error: null })
    try {
      // Calculate date range for the week
      const endDate = new Date(startDate)
      endDate.setDate(startDate.getDate() + 6)
      
      // Prepare game filters
      const gameParams = teamId ? {
        home_team: teamId,
        away_team: teamId,
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      } : {
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      }

      const [events, games] = await Promise.all([
        calendarService.getEventsForWeek(startDate, teamId),
        calendarService.getGames(gameParams)
      ])
      set({ events, games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch events for week',
        isLoading: false 
      })
    }
  },

  fetchEventsForDay: async (date: Date, teamId?: number) => {
    set({ isLoading: true, error: null })
    try {
      // Calculate date range for the day
      const startDate = new Date(date)
      startDate.setHours(0, 0, 0, 0)
      const endDate = new Date(date)
      endDate.setHours(23, 59, 59, 999)
      
      // Prepare game filters
      const gameParams = teamId ? {
        home_team: teamId,
        away_team: teamId,
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      } : {
        game_date__gte: startDate.toISOString(),
        game_date__lte: endDate.toISOString()
      }

      const [events, games] = await Promise.all([
        calendarService.getEventsForDay(date, teamId),
        calendarService.getGames(gameParams)
      ])
      set({ events, games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || error.message || 'Failed to fetch events for day',
        isLoading: false 
      })
    }
  },

  // Utility functions
  clearError: () => set({ error: null }),

  getEventsForDate: (date: Date) => {
    const { events } = get()
    const dateStr = date.toDateString()
    return events.filter(event => {
      const eventDate = new Date(event.start_time).toDateString()
      return eventDate === dateStr
    })
  },

  getGamesForDate: (date: Date) => {
    const { games } = get()
    const dateStr = date.toDateString()
    return games.filter(game => {
      const gameDate = new Date(game.game_date).toDateString()
      return gameDate === dateStr
    })
  },

  getAllItemsForDate: (date: Date) => {
    const { getEventsForDate, getGamesForDate } = get()
    const events = getEventsForDate(date)
    const games = getGamesForDate(date)
    
    // Combine and sort by time
    const allItems = [...events, ...games].sort((a, b) => {
      const timeA = new Date('start_time' in a ? a.start_time : a.game_date).getTime()
      const timeB = new Date('start_time' in b ? b.start_time : b.game_date).getTime()
      return timeA - timeB
    })
    
    return allItems
  }
}))
