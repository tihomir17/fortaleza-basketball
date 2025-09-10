import { useEffect, useState } from 'react'
import { eventsApi } from '../services/api'
import { Button } from '../components/ui/Button'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'

type EventItem = {
  id: number
  title: string
  description?: string
  start_time: string
  end_time?: string
  location?: string
  event_type?: string
}

export function Events() {
  const [items, setItems] = useState<EventItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Filters & pagination
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [hasNext, setHasNext] = useState(false)

  const [creating, setCreating] = useState(false)
  const [form, setForm] = useState({
    title: '',
    start_time: '',
    end_time: '',
    location: '',
    event_type: 'Team Practice',
    description: '',
    recurrence_rule: '', // e.g., FREQ=WEEKLY;BYDAY=MO,WE;COUNT=8
    send_notifications: false,
  })

  const [editingId, setEditingId] = useState<number | null>(null)
  const [editForm, setEditForm] = useState({
    title: '',
    start_time: '',
    end_time: '',
    location: '',
    event_type: 'meeting',
    description: ''
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

  // Notifications (browser local reminders)
  const scheduleReminder = async (ev: EventItem, minutesBefore = 30) => {
    try {
      if (!('Notification' in window)) return
      if (Notification.permission !== 'granted') {
        await Notification.requestPermission()
      }
      if (Notification.permission !== 'granted') return

      const start = new Date(ev.start_time).getTime()
      const triggerAt = start - minutesBefore * 60 * 1000
      const delay = Math.max(0, triggerAt - Date.now())
      // Best-effort local reminder (tab must be open)
      setTimeout(() => {
        new Notification('Event Reminder', {
          body: `${ev.title} starts in ${minutesBefore} min${ev.location ? ' @ ' + ev.location : ''}`,
        })
      }, delay)
    } catch {
      // ignore
    }
  }

  // External calendar helpers
  const toDateTimeStamp = (iso: string) => {
    const d = new Date(iso)
    return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
  }

  const googleCalendarLink = (ev: EventItem) => {
    const start = toDateTimeStamp(ev.start_time)
    const end = toDateTimeStamp(ev.end_time || ev.start_time)
    const params = new URLSearchParams({
      action: 'TEMPLATE',
      text: ev.title || 'Event',
      dates: `${start}/${end}`,
      details: ev.description || '',
      location: ev.location || '',
    })
    return `https://calendar.google.com/calendar/render?${params.toString()}`
  }

  const outlookCalendarLink = (ev: EventItem) => {
    const start = new Date(ev.start_time).toISOString()
    const end = new Date(ev.end_time || ev.start_time).toISOString()
    const params = new URLSearchParams({
      path: '/calendar/action/compose',
      rru: 'addevent',
      startdt: start,
      enddt: end,
      subject: ev.title || 'Event',
      body: ev.description || '',
      location: ev.location || '',
    })
    return `https://outlook.live.com/calendar/0/deeplink/compose?${params.toString()}`
  }

  const downloadIcs = (ev: EventItem) => {
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
      `LOCATION:${(ev.location || '').replace(/\n/g, ' ')}`,
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
    setLoading(true)
    setError(null)
    try {
      const params: any = { page, limit }
      if (search) params.search = search
      if (typeFilter) params.event_type = typeFilter
      if (fromDate) params.from = fromDate
      if (toDate) params.to = toDate
      const data = await eventsApi.getEvents(params)
      // API root appears to return a DRF list (likely array) – normalize
      const list = Array.isArray((data as any)) ? (data as any) : (data as any)?.results || []
      const next = (data as any)?.next
      setHasNext(Boolean(next))
      setItems(list as EventItem[])
    } catch (e: any) {
      setError(e?.message || 'Failed to load events')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const submit = async () => {
    if (!form.title || !form.start_time) return
    setCreating(true)
    setError(null)
    try {
      const payload: any = {
        title: form.title,
        start_time: form.start_time,
      }
      if (form.end_time) payload.end_time = form.end_time
      if (form.location) payload.location = form.location
      if (form.event_type) payload.event_type = form.event_type
      if (form.description) payload.description = form.description
      // Optional enhancements
      if (form.recurrence_rule) payload.recurrence_rule = form.recurrence_rule
      if (form.send_notifications) payload.send_notifications = true
      await eventsApi.createEvent(payload)
      setForm({ title: '', start_time: '', end_time: '', location: '', event_type: 'meeting', description: '', recurrence_rule: '', send_notifications: false })
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to create event')
    } finally {
      setCreating(false)
    }
  }

  const startEdit = (ev: EventItem) => {
    setEditingId(ev.id)
    setEditForm({
      title: ev.title || '',
      start_time: ev.start_time ? ev.start_time.slice(0, 16) : '',
      end_time: ev.end_time ? ev.end_time.slice(0, 16) : '',
      location: ev.location || '',
      event_type: ev.event_type || 'meeting',
      description: ev.description || ''
    })
  }

  const cancelEdit = () => setEditingId(null)

  const saveEdit = async (id: number) => {
    setError(null)
    try {
      const payload: any = {
        title: editForm.title,
        start_time: editForm.start_time,
      }
      if (editForm.end_time) payload.end_time = editForm.end_time
      if (editForm.location) payload.location = editForm.location
      if (editForm.event_type) payload.event_type = editForm.event_type
      if (editForm.description) payload.description = editForm.description
      await eventsApi.updateEvent(String(id), payload)
      setEditingId(null)
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to update event')
    }
  }

  const remove = async (id: number) => {
    setError(null)
    try {
      await eventsApi.deleteEvent(String(id))
      await load()
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
                      onChange={e => setForm(f => ({ ...f, event_type: e.target.value }))}>
                <option>Team Practice</option>
                <option>Individual Practice</option>
                <option>Scouting Meeting</option>
                <option>Strength & Conditioning</option>
                <option>Game</option>
                <option>Team Meeting</option>
                <option>Travel (Bus)</option>
                <option>Travel (Plane)</option>
                <option>Team Building</option>
                <option>Other</option>
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
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Location</label>
              <input className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                     value={form.location}
                     onChange={e => setForm(f => ({ ...f, location: e.target.value }))} />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description</label>
              <textarea rows={3} className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                        value={form.description}
                        onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Recurrence Rule (RFC5545)</label>
              <input className="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                     placeholder="e.g., FREQ=WEEKLY;BYDAY=MO,WE;COUNT=8"
                     value={form.recurrence_rule}
                     onChange={e => setForm(f => ({ ...f, recurrence_rule: e.target.value }))} />
              <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">Optional — backend must support recurrence expansion.</p>
            </div>
            <div className="flex items-center gap-2">
              <input id="notify" type="checkbox" className="h-4 w-4" checked={form.send_notifications}
                     onChange={e => setForm(f => ({ ...f, send_notifications: e.target.checked }))} />
              <label htmlFor="notify" className="text-sm text-gray-700 dark:text-gray-300">Send email notifications</label>
            </div>
          </div>
          <div className="mt-4 flex items-center gap-3">
            <Button onClick={submit} loading={creating} disabled={!form.title || !form.start_time}>
              Create Event
            </Button>
            {error && <span className="text-sm text-red-600 dark:text-red-400">{error}</span>}
          </div>
        </CardContent>
      </Card>

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
              <option>Team Practice</option>
              <option>Individual Practice</option>
              <option>Scouting Meeting</option>
              <option>Strength & Conditioning</option>
              <option>Game</option>
              <option>Team Meeting</option>
              <option>Travel (Bus)</option>
              <option>Travel (Plane)</option>
              <option>Team Building</option>
              <option>Other</option>
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
                              onChange={e => setEditForm(f => ({ ...f, event_type: e.target.value }))}>
                        <option value="meeting">Meeting</option>
                        <option value="practice">Practice</option>
                        <option value="game">Game</option>
                        <option value="travel">Travel</option>
                        <option value="other">Other</option>
                      </select>
                      <input type="datetime-local" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             value={editForm.start_time}
                             onChange={e => setEditForm(f => ({ ...f, start_time: e.target.value }))} />
                      <input type="datetime-local" className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             value={editForm.end_time}
                             onChange={e => setEditForm(f => ({ ...f, end_time: e.target.value }))} />
                      <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                             placeholder="Location"
                             value={editForm.location}
                             onChange={e => setEditForm(f => ({ ...f, location: e.target.value }))} />
                      <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 md:col-span-2"
                             placeholder="Description"
                             value={editForm.description}
                             onChange={e => setEditForm(f => ({ ...f, description: e.target.value }))} />
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
                          {new Date(ev.start_time).toLocaleString()} {ev.location ? `• ${ev.location}` : ''} {ev.event_type ? `• ${ev.event_type}` : ''}
                        </div>
                        {ev.description && (
                          <div className="text-sm text-gray-600 dark:text-gray-400">{ev.description}</div>
                        )}
                        <div className="mt-2 text-xs text-gray-600 dark:text-gray-400">Availability: <span className="font-medium">{rsvp[ev.id] || '—'}</span></div>
                      </div>
                      <div className="flex-shrink-0 flex flex-wrap gap-2">
                        <Button variant="outline" onClick={() => startEdit(ev)}>Edit</Button>
                        <Button variant="danger" onClick={() => remove(ev.id)}>Delete</Button>
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'going')}>Going</Button>
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'maybe')}>Maybe</Button>
                        <Button variant="outline" onClick={() => updateRsvp(ev.id, 'declined')}>Decline</Button>
                        <a className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-sm text-gray-700 dark:text-gray-300 hover:bg-white/50"
                           href={googleCalendarLink(ev)} target="_blank" rel="noreferrer">Google</a>
                        <a className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-600 text-sm text-gray-700 dark:text-gray-300 hover:bg-white/50"
                           href={outlookCalendarLink(ev)} target="_blank" rel="noreferrer">Outlook</a>
                        <Button variant="outline" onClick={() => downloadIcs(ev)}>ICS</Button>
                        <Button onClick={() => scheduleReminder(ev, 30)}>Remind 30m</Button>
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
