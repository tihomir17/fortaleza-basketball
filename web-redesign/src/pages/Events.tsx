import { useEffect, useState } from 'react'
import { calendarService, type CalendarEvent, type CalendarEventCreate } from '../services/calendar'
import { useTeamsStore } from '../store/teamsStore'
import { useAuthStore } from '../store/authStore'
import { notify } from '../store/notificationsStore'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Button } from '../components/ui/Button'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'

// Helper functions for event permissions
const canCreateEvent = (user: any) => {
  if (!user) return false
  return user.role === 'COACH' || user.role === 'ADMIN' || 
         (user.role === 'STAFF' && user.staff_type === 'MANAGEMENT')
}

const canEditEvent = (user: any, event: CalendarEvent) => {
  if (!user) return false
  // Coach can edit all events
  if (user.role === 'COACH' || user.role === 'ADMIN') return true
  // Management can edit events they created or certain types
  if (user.role === 'STAFF' && user.staff_type === 'MANAGEMENT') {
    return event.created_by === user.id || 
           ['TEAM_MEETING', 'TRAVEL_BUS', 'TRAVEL_PLANE'].includes(event.event_type)
  }
  return false
}

const canDeleteEvent = (user: any, event: CalendarEvent) => {
  if (!user) return false
  // Coach can delete all events
  if (user.role === 'COACH' || user.role === 'ADMIN') return true
  // Management can delete events they created
  if (user.role === 'STAFF' && user.staff_type === 'MANAGEMENT') {
    return event.created_by === user.id
  }
  return false
}

export function Events() {
  const [items, setItems] = useState<CalendarEvent[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const { isAuthenticated, user } = useAuthStore()
  const { teams, fetchTeams } = useTeamsStore()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    }
  }, [isAuthenticated, navigate])

  // Filters & pagination
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [hasNext, setHasNext] = useState(false)

  const [creating, setCreating] = useState(false)
  const [form, setForm] = useState<CalendarEventCreate>({
    title: '',
    start_time: '',
    end_time: '',
    event_type: 'PRACTICE_TEAM',
    description: '',
    team: undefined,
    attendees: []
  })
  const [conflicts, setConflicts] = useState<CalendarEvent[]>([])

  const [editingId, setEditingId] = useState<number | null>(null)
  const [editForm, setEditForm] = useState<Partial<CalendarEventCreate>>({
    title: '',
    start_time: '',
    end_time: '',
    event_type: 'PRACTICE_TEAM',
    description: '',
    team: undefined,
    attendees: []
  })

  // Local availability (RSVP) storage
  const [rsvp, setRsvp] = useState<Record<number, 'going' | 'maybe' | 'declined'>>(() => {
    try {
      const raw = localStorage.getItem('event_rsvp')
      return raw ? JSON.parse(raw) : {}
    } catch {
      return {}
    }
  })

  const updateRsvp = (id: number, status: 'going' | 'maybe' | 'declined') => {
    setRsvp(prev => {
      const next = { ...prev, [id]: status }
      localStorage.setItem('event_rsvp', JSON.stringify(next))
      return next
    })
  }

  // Check for scheduling conflicts
  const checkConflicts = (startTime: string, endTime: string, excludeId?: number) => {
    if (!startTime) return []
    
    const start = new Date(startTime)
    const end = new Date(endTime || startTime)
    
    const conflictingEvents = items.filter(event => {
      if (excludeId && event.id === excludeId) return false
      
      const eventStart = new Date(event.start_time)
      const eventEnd = new Date(event.end_time || event.start_time)
      
      // Check for overlap: events overlap if one starts before the other ends
      return (start < eventEnd && end > eventStart)
    })
    
    return conflictingEvents
  }

  // Enhanced reminder system
  const scheduleReminder = async (ev: CalendarEvent, minutesBefore = 30) => {
    try {
      if (!('Notification' in window)) {
        notify.warning('Notifications Not Supported', 'Your browser does not support notifications.')
        return
      }
      
      if (Notification.permission !== 'granted') {
        const permission = await Notification.requestPermission()
        if (permission !== 'granted') {
          notify.warning('Permission Denied', 'Please enable notifications to receive reminders.')
          return
        }
      }

      const start = new Date(ev.start_time).getTime()
      const triggerAt = start - minutesBefore * 60 * 1000
      const delay = Math.max(0, triggerAt - Date.now())
      
      if (delay > 0) {
        // Store reminder in localStorage for persistence
        const reminderId = `reminder_${ev.id}_${minutesBefore}`
        const reminder = {
          id: reminderId,
          eventId: ev.id,
          eventTitle: ev.title,
          triggerTime: triggerAt,
          minutesBefore
        }
        
        const existingReminders = JSON.parse(localStorage.getItem('eventReminders') || '[]')
        existingReminders.push(reminder)
        localStorage.setItem('eventReminders', JSON.stringify(existingReminders))
        
        // Schedule the reminder
        setTimeout(() => {
          new Notification('Event Reminder', {
            body: `${ev.title} starts in ${minutesBefore} minutes`,
            icon: '/favicon.ico'
          })
          
          // Remove from localStorage
          const updatedReminders = existingReminders.filter((r: any) => r.id !== reminderId)
          localStorage.setItem('eventReminders', JSON.stringify(updatedReminders))
          
          // Add to notifications store
          notify.info('Event Reminder', `${ev.title} starts in ${minutesBefore} minutes`)
        }, delay)
        
        notify.success('Reminder Set', `You'll be reminded ${minutesBefore} minutes before "${ev.title}"`)
      } else {
        notify.warning('Invalid Time', 'Cannot set reminder for past events.')
      }
    } catch (error) {
      notify.error('Reminder Error', 'Failed to set reminder. Please try again.')
    }
  }

  // Load existing reminders on component mount
  useEffect(() => {
    const existingReminders = JSON.parse(localStorage.getItem('eventReminders') || '[]')
    const now = Date.now()
    
    // Check for overdue reminders and clean them up
    const validReminders = existingReminders.filter((reminder: any) => reminder.triggerTime > now)
    if (validReminders.length !== existingReminders.length) {
      localStorage.setItem('eventReminders', JSON.stringify(validReminders))
    }
  }, [])

  // External calendar helpers
  const toDateTimeStamp = (iso: string) => {
    const d = new Date(iso)
    return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
  }

  const googleCalendarLink = (ev: CalendarEvent) => {
    const start = toDateTimeStamp(ev.start_time)
    const end = toDateTimeStamp(ev.end_time || ev.start_time)
    const params = new URLSearchParams({
      action: 'TEMPLATE',
      text: ev.title || 'Event',
      dates: `${start}/${end}`,
      details: ev.description || '',
    })
    return `https://calendar.google.com/calendar/render?${params.toString()}`
  }

  const outlookCalendarLink = (ev: CalendarEvent) => {
    const start = new Date(ev.start_time).toISOString()
    const end = new Date(ev.end_time || ev.start_time).toISOString()
    const params = new URLSearchParams({
      path: '/calendar/action/compose',
      rru: 'addevent',
      startdt: start,
      enddt: end,
      subject: ev.title || 'Event',
      body: ev.description || '',
    })
    return `https://outlook.live.com/calendar/0/deeplink/compose?${params.toString()}`
  }

  const downloadIcs = (ev: CalendarEvent) => {
    const dtstamp = toDateTimeStamp(new Date().toISOString())
    const dtstart = toDateTimeStamp(ev.start_time)
    const dtend = toDateTimeStamp(ev.end_time || ev.start_time)
    const uid = `event-${ev.id}@fortaleza`
    const ics = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Fortaleza//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      `UID:${uid}`,
      `DTSTAMP:${dtstamp}`,
      `DTSTART:${dtstart}`,
      `DTEND:${dtend}`,
      `SUMMARY:${(ev.title || 'Event').replace(/\n/g, ' ')}`,
      `DESCRIPTION:${(ev.description || '').replace(/\n/g, ' ')}`,
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n')

    const blob = new Blob([ics], { type: 'text/calendar;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${(ev.title || 'event').replace(/\s+/g, '_')}.ics`
    document.body.appendChild(a)
    a.click()
    a.remove()
    URL.revokeObjectURL(url)
  }

  const load = async () => {
    if (!isAuthenticated) return
    
    setLoading(true)
    setError(null)
    try {
      const params: any = {}
      if (typeFilter) params.event_type = typeFilter
      if (fromDate) params.start_time__gte = fromDate
      if (toDate) params.end_time__lte = toDate
      
      const events = await calendarService.getEvents(params)
      
      // Filter by search term on the frontend since backend doesn't support search
      let filteredEvents = events
      if (search) {
        filteredEvents = events.filter(event => 
          event.title.toLowerCase().includes(search.toLowerCase()) ||
          (event.description && event.description.toLowerCase().includes(search.toLowerCase()))
        )
      }
      
      setItems(filteredEvents)
      setHasNext(false) // Calendar service doesn't support pagination yet
    } catch (e: any) {
      setError(e?.message || 'Failed to load events')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTeams()
    load()
  }, [fetchTeams])

  // Pre-select user's team when creating events
  useEffect(() => {
    if (user && teams.length > 0 && !form.team) {
      // If user is a coach or staff, pre-select their first team
      if ((user.role === 'COACH' || user.role === 'STAFF') && teams.length > 0) {
        setForm(prev => ({ ...prev, team: teams[0].id }))
      }
    }
  }, [user, teams, form.team])

  // Handle creating event from game
  useEffect(() => {
    const gameId = searchParams.get('createFromGame')
    if (gameId) {
      // Fetch game data and pre-populate form
      const fetchGameData = async () => {
        try {
          const games = await calendarService.getGames()
          const game = games.find(g => g.id === parseInt(gameId))
          if (game) {
            setForm(prev => ({
              ...prev,
              title: `${game.home_team.name} vs ${game.away_team.name}`,
              start_time: new Date(game.game_date).toISOString().slice(0, 16),
              end_time: new Date(new Date(game.game_date).getTime() + 2 * 60 * 60 * 1000).toISOString().slice(0, 16), // 2 hours later
              event_type: 'GAME',
              description: `Game: ${game.home_team.name} vs ${game.away_team.name}`,
              team: game.home_team.id
            }))
          }
        } catch (error) {
          console.error('Error fetching game data:', error)
        }
      }
      fetchGameData()
    }
  }, [searchParams])

  // Check for conflicts when form changes
  useEffect(() => {
    if (form.start_time) {
      const conflicts = checkConflicts(form.start_time, form.end_time || form.start_time)
      setConflicts(conflicts)
    } else {
      setConflicts([])
    }
  }, [form.start_time, form.end_time, items])

  // Check for conflicts when editing
  useEffect(() => {
    if (editingId && editForm.start_time) {
      const conflicts = checkConflicts(editForm.start_time, editForm.end_time || editForm.start_time, editingId)
      setConflicts(conflicts)
    } else if (!editingId) {
      setConflicts([])
    }
  }, [editForm.start_time, editForm.end_time, editingId, items])

  const submit = async () => {
    if (!form.title || !form.start_time) return
    setCreating(true)
    setError(null)
    try {
      const payload: CalendarEventCreate = {
        title: form.title,
        start_time: form.start_time,
        end_time: form.end_time || form.start_time, // Use start_time as end_time if not provided
        event_type: form.event_type,
        description: form.description,
        team: form.team,
        attendees: form.attendees
      }
      
      await calendarService.createEvent(payload)
      setForm({ 
        title: '', 
        start_time: '', 
        end_time: '', 
        event_type: 'PRACTICE_TEAM', 
        description: '', 
        team: undefined,
        attendees: []
      })
      await load()
      notify.success('Event Created', `"${payload.title}" has been successfully created.`)
    } catch (e: any) {
      setError(e?.message || 'Failed to create event')
    } finally {
      setCreating(false)
    }
  }

  const startEdit = (ev: CalendarEvent) => {
    setEditingId(ev.id)
    setEditForm({
      title: ev.title || '',
      start_time: ev.start_time ? ev.start_time.slice(0, 16) : '',
      end_time: ev.end_time ? ev.end_time.slice(0, 16) : '',
      event_type: ev.event_type || 'PRACTICE_TEAM',
      description: ev.description || '',
      team: typeof ev.team === 'object' ? ev.team?.id : ev.team,
      attendees: Array.isArray(ev.attendees) ? ev.attendees.map((a: any) => typeof a === 'object' ? a.id : a) : []
    })
  }

  const cancelEdit = () => setEditingId(null)

  const saveEdit = async (id: number) => {
    setError(null)
    try {
      const payload: Partial<CalendarEventCreate> = {
        title: editForm.title,
        start_time: editForm.start_time,
        end_time: editForm.end_time,
        event_type: editForm.event_type,
        description: editForm.description,
        team: editForm.team,
        attendees: editForm.attendees
      }
      await calendarService.updateEvent(id, payload)
      setEditingId(null)
      await load()
      notify.success('Event Updated', `"${payload.title}" has been successfully updated.`)
    } catch (e: any) {
      setError(e?.message || 'Failed to update event')
    }
  }

  const remove = async (id: number) => {
    setError(null)
    try {
      const event = items.find(e => e.id === id)
      await calendarService.deleteEvent(id)
      await load()
      notify.success('Event Deleted', `"${event?.title || 'Event'}" has been successfully deleted.`)
    } catch (e: any) {
      setError(e?.message || 'Failed to delete event')
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Events</h1>
        <p className="text-gray-600 dark:text-gray-400">Schedule practices, games, meetings and more.</p>
      </div>

      {canCreateEvent(user) && (
        <Card>
          <CardHeader>
            <CardTitle>Create Event</CardTitle>
          </CardHeader>
          <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Title</label>
              <input className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                     value={form.title}
                     onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Type</label>
              <select className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                      value={form.event_type}
                      onChange={e => setForm(f => ({ ...f, event_type: e.target.value as any }))}>
                <option value="PRACTICE_TEAM">Team Practice</option>
                <option value="PRACTICE_INDIVIDUAL">Individual Practice</option>
                <option value="SCOUTING_MEETING">Scouting Meeting</option>
                <option value="STRENGTH_CONDITIONING">Strength & Conditioning</option>
                <option value="GAME">Game</option>
                <option value="TEAM_MEETING">Team Meeting</option>
                <option value="TRAVEL_BUS">Travel (Bus)</option>
                <option value="TRAVEL_PLANE">Travel (Plane)</option>
                <option value="TEAM_BUILDING">Team Building</option>
                <option value="OTHER">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Team</label>
              <select className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                      value={form.team || ''}
                      onChange={e => setForm(f => ({ ...f, team: e.target.value ? Number(e.target.value) : undefined }))}>
                <option value="">No Team</option>
                {teams.map(team => (
                  <option key={team.id} value={team.id}>{team.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Start</label>
              <input type="datetime-local" className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                     value={form.start_time}
                     onChange={e => setForm(f => ({ ...f, start_time: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">End</label>
              <input type="datetime-local" className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                     value={form.end_time}
                     onChange={e => setForm(f => ({ ...f, end_time: e.target.value }))} />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description</label>
              <textarea rows={3} className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                        value={form.description}
                        onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
          </div>
          {conflicts.length > 0 && (
            <div className="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
              <div className="flex items-start gap-2">
                <div className="text-yellow-600 dark:text-yellow-400">⚠️</div>
                <div>
                  <div className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                    Scheduling Conflict Detected
                  </div>
                  <div className="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                    This event conflicts with {conflicts.length} existing event{conflicts.length > 1 ? 's' : ''}:
                  </div>
                  <ul className="text-sm text-yellow-700 dark:text-yellow-300 mt-1 ml-4 list-disc">
                    {conflicts.map(conflict => (
                      <li key={conflict.id}>
                        {conflict.title} ({new Date(conflict.start_time).toLocaleString()})
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          )}
          <div className="mt-4 flex items-center gap-3">
            <Button onClick={submit} loading={creating} disabled={!form.title || !form.start_time}>
              Create Event
            </Button>
            {error && <span className="text-sm text-red-600 dark:text-red-400">{error}</span>}
          </div>
        </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Upcoming Events</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="mb-4 grid grid-cols-1 md:grid-cols-6 gap-3">
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Search title/description"
                   value={search}
                   onChange={e => setSearch(e.target.value)} />
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={typeFilter}
                    onChange={e => setTypeFilter(e.target.value)}>
              <option value="">All Types</option>
              <option value="PRACTICE_TEAM">Team Practice</option>
              <option value="PRACTICE_INDIVIDUAL">Individual Practice</option>
              <option value="SCOUTING_MEETING">Scouting Meeting</option>
              <option value="STRENGTH_CONDITIONING">Strength & Conditioning</option>
              <option value="GAME">Game</option>
              <option value="TEAM_MEETING">Team Meeting</option>
              <option value="TRAVEL_BUS">Travel (Bus)</option>
              <option value="TRAVEL_PLANE">Travel (Plane)</option>
              <option value="TEAM_BUILDING">Team Building</option>
              <option value="OTHER">Other</option>
            </select>
            <input type="date" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                   value={fromDate}
                   onChange={e => setFromDate(e.target.value)} />
            <input type="date" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                   value={toDate}
                   onChange={e => setToDate(e.target.value)} />
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={limit}
                    onChange={e => { setLimit(Number(e.target.value) || 10); setPage(1) }}>
              <option value={10}>10</option>
              <option value={20}>20</option>
              <option value={50}>50</option>
            </select>
            <div className="flex items-center gap-2">
              <Button variant="outline" onClick={() => { setPage(1); load() }}>Apply</Button>
              <Button variant="outline" onClick={() => { setSearch(''); setTypeFilter(''); setFromDate(''); setToDate(''); setPage(1); }}>Reset</Button>
            </div>
          </div>
          {loading ? (
            <div className="text-gray-600 dark:text-gray-400">Loading…</div>
          ) : (
            <div className="divide-y divide-gray-200 dark:divide-gray-700">
              {items.length === 0 && (
                <div className="text-gray-600 dark:text-gray-400">No events yet.</div>
              )}
              {items.map(ev => (
                <div key={ev.id} className="py-3">
                  {editingId === ev.id ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             value={editForm.title}
                             onChange={e => setEditForm(f => ({ ...f, title: e.target.value }))} />
                      <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                              value={editForm.event_type}
                              onChange={e => setEditForm(f => ({ ...f, event_type: e.target.value as any }))}>
                        <option value="PRACTICE_TEAM">Team Practice</option>
                        <option value="PRACTICE_INDIVIDUAL">Individual Practice</option>
                        <option value="SCOUTING_MEETING">Scouting Meeting</option>
                        <option value="STRENGTH_CONDITIONING">Strength & Conditioning</option>
                        <option value="GAME">Game</option>
                        <option value="TEAM_MEETING">Team Meeting</option>
                        <option value="TRAVEL_BUS">Travel (Bus)</option>
                        <option value="TRAVEL_PLANE">Travel (Plane)</option>
                        <option value="TEAM_BUILDING">Team Building</option>
                        <option value="OTHER">Other</option>
                      </select>
                      <input type="datetime-local" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             value={editForm.start_time}
                             onChange={e => setEditForm(f => ({ ...f, start_time: e.target.value }))} />
                      <input type="datetime-local" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             value={editForm.end_time}
                             onChange={e => setEditForm(f => ({ ...f, end_time: e.target.value }))} />
                      <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 md:col-span-2"
                             placeholder="Description"
                             value={editForm.description}
                             onChange={e => setEditForm(f => ({ ...f, description: e.target.value }))} />
                      {conflicts.length > 0 && (
                        <div className="md:col-span-2 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                          <div className="flex items-start gap-2">
                            <div className="text-yellow-600 dark:text-yellow-400">⚠️</div>
                            <div>
                              <div className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                                Scheduling Conflict Detected
                              </div>
                              <div className="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                                This change conflicts with {conflicts.length} existing event{conflicts.length > 1 ? 's' : ''}:
                              </div>
                              <ul className="text-sm text-yellow-700 dark:text-yellow-300 mt-1 ml-4 list-disc">
                                {conflicts.map(conflict => (
                                  <li key={conflict.id}>
                                    {conflict.title} ({new Date(conflict.start_time).toLocaleString()})
                                  </li>
                                ))}
                              </ul>
                            </div>
                          </div>
                        </div>
                      )}
                      <div className="md:col-span-2 flex gap-2">
                        <Button onClick={() => saveEdit(ev.id)}>Save</Button>
                        <Button variant="outline" onClick={cancelEdit}>Cancel</Button>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <div className="font-medium text-gray-900 dark:text-white">{ev.title}</div>
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          {new Date(ev.start_time).toLocaleString()} • {ev.event_type?.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, l => l.toUpperCase())}
                        </div>
                        {ev.description && (
                          <div className="text-sm text-gray-600 dark:text-gray-400">{ev.description}</div>
                        )}
                        <div className="mt-2 text-xs text-gray-600 dark:text-gray-400">Availability: <span className="font-medium">{rsvp[ev.id] || '—'}</span></div>
                      </div>
                      <div className="flex-shrink-0 flex flex-wrap gap-2">
                        {canEditEvent(user, ev) && (
                          <Button variant="outline" onClick={() => startEdit(ev)}>Edit</Button>
                        )}
                        {canDeleteEvent(user, ev) && (
                          <Button variant="danger" onClick={() => remove(ev.id)}>Delete</Button>
                        )}
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'going')}>Going</Button>
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'maybe')}>Maybe</Button>
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'declined')}>Decline</Button>
                        <a className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-sm text-gray-700 dark:text-gray-300 hover:bg-white/50"
                           href={googleCalendarLink(ev)} target="_blank" rel="noreferrer">Google</a>
                        <a className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-sm text-gray-700 dark:text-gray-300 hover:bg-white/50"
                           href={outlookCalendarLink(ev)} target="_blank" rel="noreferrer">Outlook</a>
                        <Button variant="outline" onClick={() => downloadIcs(ev)}>ICS</Button>
                        <div className="flex gap-1">
                          <Button size="sm" onClick={() => scheduleReminder(ev, 15)}>15m</Button>
                          <Button size="sm" onClick={() => scheduleReminder(ev, 30)}>30m</Button>
                          <Button size="sm" onClick={() => scheduleReminder(ev, 60)}>1h</Button>
                          <Button size="sm" onClick={() => scheduleReminder(ev, 1440)}>1d</Button>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
          <div className="mt-4 flex items-center justify-between">
            <Button variant="outline" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>Prev</Button>
            <div className="text-sm text-gray-600 dark:text-gray-400">Page {page}</div>
            <Button variant="outline" onClick={() => hasNext && setPage(p => p + 1)} disabled={!hasNext}>Next</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
