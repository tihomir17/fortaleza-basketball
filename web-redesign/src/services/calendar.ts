import api from './api'

export interface CalendarEvent {
  id: number
  title: string
  description?: string
  start_time: string
  end_time: string
  event_type: 'PRACTICE_TEAM' | 'PRACTICE_INDIVIDUAL' | 'SCOUTING_MEETING' | 'STRENGTH_CONDITIONING' | 'GAME' | 'TEAM_MEETING' | 'TRAVEL_BUS' | 'TRAVEL_PLANE' | 'TEAM_BUILDING' | 'OTHER'
  team?: {
    id: number
    name: string
  }
  attendees?: Array<{
    id: number
    username: string
    first_name: string
    last_name: string
  }>
  created_by: number
}

export interface CalendarEventCreate {
  title: string
  description?: string
  start_time: string
  end_time: string
  event_type: CalendarEvent['event_type']
  team?: number
  attendees?: number[]
}

export interface CalendarEventUpdate extends Partial<CalendarEventCreate> {
  id: number
}

export interface GameEvent {
  id: number
  home_team: {
    id: number
    name: string
  }
  away_team: {
    id: number
    name: string
  }
  competition: {
    id: number
    name: string
  }
  game_date: string
  home_team_score?: number
  away_team_score?: number
  quarter?: number
  created_by?: number
  created_at: string
  updated_at: string
}

export interface CalendarData {
  events: CalendarEvent[]
  games: GameEvent[]
}

export const calendarService = {
  // Get all calendar events
  async getEvents(params?: {
    team?: number
    event_type?: string
    start_time__gte?: string
    start_time__lte?: string
    end_time__gte?: string
    end_time__lte?: string
  }): Promise<CalendarEvent[]> {
    try {
      const data = await api.get<any>('/events/', { params })
      
      // Handle paginated response (DRF PageNumberPagination)
      if (data && data.results) {
        return data.results
      }
      
      // Handle non-paginated response
      return Array.isArray(data) ? data : []
    } catch (error: any) {
      console.error('Error fetching events:', error)
      // If it's an authentication error, return empty array
      if (error.response?.status === 401) {
        console.warn('User not authenticated - returning empty events list')
        return []
      }
      throw error
    }
  },

  // Get a specific event
  async getEvent(id: number): Promise<CalendarEvent> {
    return await api.get(`/events/${id}/`)
  },

  // Create a new event
  async createEvent(eventData: CalendarEventCreate): Promise<CalendarEvent> {
    return await api.post('/events/', eventData)
  },

  // Update an event
  async updateEvent(id: number, eventData: Partial<CalendarEventCreate>): Promise<CalendarEvent> {
    return await api.patch(`/events/${id}/`, eventData)
  },

  // Delete an event
  async deleteEvent(id: number): Promise<void> {
    await api.delete(`/events/${id}/`)
  },

  // Get games for calendar
  async getGames(params?: {
    home_team?: number
    away_team?: number
    game_date__gte?: string
    game_date__lte?: string
  }): Promise<GameEvent[]> {
    try {
      // Use the regular games endpoint with filtering instead of calendar-data
      const data = await api.get<any>('/games/', { params })
      
      // Handle paginated response (DRF PageNumberPagination)
      if (data && data.results) {
        return data.results
      }
      
      // Handle non-paginated response
      return Array.isArray(data) ? data : []
    } catch (error: any) {
      console.error('Error fetching games:', error)
      // If it's an authentication error, return empty array
      if (error.response?.status === 401) {
        console.warn('User not authenticated - returning empty games list')
        return []
      }
      throw error
    }
  },

  // Get combined calendar data (events + games)
  async getCalendarData(params?: {
    team?: number
    event_type?: string
    start_time__gte?: string
    start_time__lte?: string
    end_time__gte?: string
    end_time__lte?: string
  }): Promise<CalendarData> {
    // Prepare game filters from event params
    const gameParams = params?.team ? {
      home_team: params.team,
      away_team: params.team,
      game_date__gte: params.start_time__gte,
      game_date__lte: params.start_time__lte
    } : {
      game_date__gte: params?.start_time__gte,
      game_date__lte: params?.start_time__lte
    }

    const [events, games] = await Promise.all([
      this.getEvents(params),
      this.getGames(gameParams)
    ])

    return { events, games }
  },

  // Get events for a specific date range
  async getEventsForDateRange(startDate: Date, endDate: Date, teamId?: number): Promise<CalendarEvent[]> {
    const params = {
      start_time__gte: startDate.toISOString(),
      start_time__lte: endDate.toISOString(),
      ...(teamId && { team: teamId })
    }
    return this.getEvents(params)
  },

  // Get events for a specific month
  async getEventsForMonth(year: number, month: number, teamId?: number): Promise<CalendarEvent[]> {
    const startDate = new Date(year, month, 1)
    const endDate = new Date(year, month + 1, 0, 23, 59, 59)
    return this.getEventsForDateRange(startDate, endDate, teamId)
  },

  // Get events for a specific week
  async getEventsForWeek(startDate: Date, teamId?: number): Promise<CalendarEvent[]> {
    const endDate = new Date(startDate)
    endDate.setDate(startDate.getDate() + 6)
    endDate.setHours(23, 59, 59)
    return this.getEventsForDateRange(startDate, endDate, teamId)
  },

  // Get events for a specific day
  async getEventsForDay(date: Date, teamId?: number): Promise<CalendarEvent[]> {
    const startDate = new Date(date)
    startDate.setHours(0, 0, 0, 0)
    const endDate = new Date(date)
    endDate.setHours(23, 59, 59, 999)
    return this.getEventsForDateRange(startDate, endDate, teamId)
  }
}

export default calendarService
