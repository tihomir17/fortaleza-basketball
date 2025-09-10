import { useEffect, useState } from 'react'
import { teamsApi } from '../../services/api'
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'

type User = {
  id: number
  username?: string
  email?: string
  first_name?: string
  last_name?: string
  jersey_number?: number
  coach_type?: string
  staff_type?: string
}

type Team = {
  id: number
  name: string
  players: User[]
  coaches: User[]
  staff: User[]
}

export function Roster() {
  const [teams, setTeams] = useState<Team[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [expanded, setExpanded] = useState<Record<number, boolean>>({})

  const [addForm, setAddForm] = useState({ teamId: 0, user_id: '', role: 'player', staff_type: '' })
  const [creatingPlayer, setCreatingPlayer] = useState(false)
  const [creatingCoach, setCreatingCoach] = useState(false)
  const [newPlayer, setNewPlayer] = useState({
    teamId: 0,
    email: '',
    username: '',
    first_name: '',
    last_name: '',
    jersey_number: '' as number | string
  })
  const [newCoach, setNewCoach] = useState({
    teamId: 0,
    email: '',
    username: '',
    first_name: '',
    last_name: '',
    coach_type: 'ASSISTANT_COACH'
  })

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await teamsApi.getTeams()
      const list = Array.isArray((data as any)) ? (data as any) : (data as any)?.results || []
      setTeams(list as Team[])
    } catch (e: any) {
      setError(e?.message || 'Failed to load teams')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const addMember = async () => {
    if (!addForm.teamId || !addForm.user_id || !addForm.role) return
    setError(null)
    try {
      await teamsApi.updateTeam(String(addForm.teamId), {}) // no-op to ensure auth; optional
      // use direct post to action endpoint
      await (teamsApi as any).post?.(`/teams/${addForm.teamId}/add_member/`, addForm)
        || fetch(`${(import.meta as any).env.VITE_API_BASE_URL || 'http://localhost:8000/api'}/teams/${addForm.teamId}/add_member/`, {
             method: 'POST',
             headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('auth_token') || ''}` },
             body: JSON.stringify(addForm)
           })
      setAddForm({ teamId: 0, user_id: '', role: 'player', staff_type: '' })
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to add member')
    }
  }

  const createAndAddPlayer = async () => {
    if (!newPlayer.teamId || !newPlayer.email || !newPlayer.username) return
    setCreatingPlayer(true)
    setError(null)
    try {
      await fetch(`${(import.meta as any).env.VITE_API_BASE_URL || 'http://localhost:8000/api'}/teams/${newPlayer.teamId}/create_and_add_player/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('auth_token') || ''}` },
        body: JSON.stringify({
          email: newPlayer.email,
          username: newPlayer.username,
          first_name: newPlayer.first_name,
          last_name: newPlayer.last_name,
          jersey_number: newPlayer.jersey_number ? Number(newPlayer.jersey_number) : undefined
        })
      })
      setNewPlayer({ teamId: 0, email: '', username: '', first_name: '', last_name: '', jersey_number: '' })
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to create player')
    } finally {
      setCreatingPlayer(false)
    }
  }

  const createAndAddCoach = async () => {
    if (!newCoach.teamId || !newCoach.email || !newCoach.username) return
    setCreatingCoach(true)
    setError(null)
    try {
      await fetch(`${(import.meta as any).env.VITE_API_BASE_URL || 'http://localhost:8000/api'}/teams/${newCoach.teamId}/create_and_add_coach/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('auth_token') || ''}` },
        body: JSON.stringify({
          email: newCoach.email,
          username: newCoach.username,
          first_name: newCoach.first_name,
          last_name: newCoach.last_name,
          coach_type: newCoach.coach_type
        })
      })
      setNewCoach({ teamId: 0, email: '', username: '', first_name: '', last_name: '', coach_type: 'ASSISTANT_COACH' })
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to create coach')
    } finally {
      setCreatingCoach(false)
    }
  }

  const removeMember = async (teamId: number, userId: number, role: string) => {
    setError(null)
    try {
      await fetch(`${(import.meta as any).env.VITE_API_BASE_URL || 'http://localhost:8000/api'}/teams/${teamId}/remove_member/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('auth_token') || ''}` },
        body: JSON.stringify({ user_id: userId, role })
      })
      await load()
    } catch (e: any) {
      setError(e?.message || 'Failed to remove member')
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Roster</h1>
        <p className="text-gray-600 dark:text-gray-400">Manage teams, players, coaches and staff.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add Member</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                   placeholder="Team ID"
                   value={addForm.teamId || ''}
                   onChange={e => setAddForm(f => ({ ...f, teamId: Number(e.target.value) || 0 }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                   placeholder="User ID"
                   value={addForm.user_id}
                   onChange={e => setAddForm(f => ({ ...f, user_id: e.target.value }))} />
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={addForm.role}
                    onChange={e => setAddForm(f => ({ ...f, role: e.target.value }))}>
              <option value="player">Player</option>
              <option value="coach">Coach</option>
              <option value="staff">Staff</option>
            </select>
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                   placeholder="Staff Type (if staff)"
                   value={addForm.staff_type}
                   onChange={e => setAddForm(f => ({ ...f, staff_type: e.target.value }))} />
          </div>
          <div className="mt-3">
            <Button onClick={addMember} disabled={!addForm.teamId || !addForm.user_id}>Add</Button>
            {error && <span className="ml-3 text-sm text-red-600 dark:text-red-400">{error}</span>}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Create & Add Player</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-6 gap-3">
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Team ID"
                   value={newPlayer.teamId || ''}
                   onChange={e => setNewPlayer(v => ({ ...v, teamId: Number(e.target.value) || 0 }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Email"
                   value={newPlayer.email}
                   onChange={e => setNewPlayer(v => ({ ...v, email: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Username"
                   value={newPlayer.username}
                   onChange={e => setNewPlayer(v => ({ ...v, username: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="First name"
                   value={newPlayer.first_name}
                   onChange={e => setNewPlayer(v => ({ ...v, first_name: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Last name"
                   value={newPlayer.last_name}
                   onChange={e => setNewPlayer(v => ({ ...v, last_name: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Jersey #"
                   value={newPlayer.jersey_number}
                   onChange={e => setNewPlayer(v => ({ ...v, jersey_number: e.target.value }))} />
          </div>
          <div className="mt-3">
            <Button onClick={createAndAddPlayer} loading={creatingPlayer} disabled={!newPlayer.teamId || !newPlayer.email || !newPlayer.username}>Create Player</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Create & Add Coach</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-6 gap-3">
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Team ID"
                   value={newCoach.teamId || ''}
                   onChange={e => setNewCoach(v => ({ ...v, teamId: Number(e.target.value) || 0 }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Email"
                   value={newCoach.email}
                   onChange={e => setNewCoach(v => ({ ...v, email: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Username"
                   value={newCoach.username}
                   onChange={e => setNewCoach(v => ({ ...v, username: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="First name"
                   value={newCoach.first_name}
                   onChange={e => setNewCoach(v => ({ ...v, first_name: e.target.value }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Last name"
                   value={newCoach.last_name}
                   onChange={e => setNewCoach(v => ({ ...v, last_name: e.target.value }))} />
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={newCoach.coach_type}
                    onChange={e => setNewCoach(v => ({ ...v, coach_type: e.target.value }))}>
              <option value="HEAD_COACH">HEAD_COACH</option>
              <option value="ASSISTANT_COACH">ASSISTANT_COACH</option>
            </select>
          </div>
          <div className="mt-3">
            <Button onClick={createAndAddCoach} loading={creatingCoach} disabled={!newCoach.teamId || !newCoach.email || !newCoach.username}>Create Coach</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Teams</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-gray-600 dark:text-gray-400">Loading…</div>
          ) : (
            <div className="space-y-4">
              {teams.map(team => (
                <div key={team.id} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl">
                  <div className="flex items-center justify-between">
                    <div className="font-semibold text-gray-900 dark:text-white">{team.name} (ID: {team.id})</div>
                    <Button variant="outline" onClick={() => setExpanded(s => ({ ...s, [team.id]: !s[team.id] }))}>
                      {expanded[team.id] ? 'Hide' : 'View'} roster
                    </Button>
                  </div>
                  {expanded[team.id] && (
                    <div className="mt-3 grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div>
                        <div className="text-sm font-medium text-gray-900 dark:text-white mb-2">Players ({team.players?.length || 0})</div>
                        <div className="space-y-2">
                          {team.players?.map(u => (
                            <div key={u.id} className="flex items-center justify-between text-sm text-gray-700 dark:text-gray-300">
                              <span>#{u.jersey_number ?? '-'} {u.first_name} {u.last_name} ({u.username || u.email})</span>
                              <Button variant="outline" onClick={() => removeMember(team.id, u.id, 'player')}>Remove</Button>
                            </div>
                          ))}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm font-medium text-gray-900 dark:text-white mb-2">Coaches ({team.coaches?.length || 0})</div>
                        <div className="space-y-2">
                          {team.coaches?.map(u => (
                            <div key={u.id} className="flex items-center justify-between text-sm text-gray-700 dark:text-gray-300">
                              <span>{(u.coach_type === 'HEAD_COACH' ? 'Head Coach' : u.coach_type === 'ASSISTANT_COACH' ? 'Assistant Coach' : (u.coach_type || 'Coach'))} {u.first_name} {u.last_name} ({u.username || u.email})</span>
                              <Button variant="outline" onClick={() => removeMember(team.id, u.id, 'coach')}>Remove</Button>
                            </div>
                          ))}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm font-medium text-gray-900 dark:text-white mb-2">Staff ({team.staff?.length || 0})</div>
                        <div className="space-y-2">
                          {team.staff?.map(u => (
                            <div key={u.id} className="flex items-center justify-between text-sm text-gray-700 dark:text-gray-300">
                              <span>{u.first_name} {u.last_name} {u.staff_type ? `(${u.staff_type})` : ''} ({u.username || u.email})</span>
                              <Button variant="outline" onClick={() => removeMember(team.id, u.id, 'staff')}>Remove</Button>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

export default Roster


