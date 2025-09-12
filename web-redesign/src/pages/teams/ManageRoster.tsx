import { useEffect, useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useTeamsStore } from '../../store/teamsStore'
import { 
  UserGroupIcon, 
  PencilIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline'

type Role = 'PLAYER' | 'COACH' | 'STAFF'

export function ManageRoster() {
  const { id } = useParams<{ id: string }>()
  const teamId = id ? parseInt(id) : 0
  const navigate = useNavigate()

  const {
    currentTeam,
    availableJerseyNumbers,
    searchResults,
    isLoading,
    error,
    fetchTeam,
    fetchTeamMembers,
    fetchAvailableJerseyNumbers,
    removeMemberFromTeam,
    createAndAddPlayer,
    createAndAddCoach,
    createAndAddStaff,
    addMemberToTeam,
    searchUsers,
    clearSearchResults,
    clearError,
  } = useTeamsStore()

  const [isAddOpen, setIsAddOpen] = useState(false)
  const [addMode, setAddMode] = useState<'new' | 'existing'>('new')
  const [role, setRole] = useState<Role>('PLAYER')
  const [form, setForm] = useState<{ [k: string]: string }>({})
  const [selectedExistingId, setSelectedExistingId] = useState<number | null>(null)
  
  // Default roster management
  const [defaultGameRoster, setDefaultGameRoster] = useState<number[]>([])
  const [defaultStartingFive, setDefaultStartingFive] = useState<number[]>([])
  const [isEditingRoster, setIsEditingRoster] = useState(false)

  useEffect(() => {
    if (!teamId) return
    fetchTeam(teamId)
    fetchTeamMembers(teamId)
    fetchAvailableJerseyNumbers(teamId)
    
    // Load default roster from localStorage
    const savedGameRoster = localStorage.getItem(`defaultGameRoster_${teamId}`)
    const savedStartingFive = localStorage.getItem(`defaultStartingFive_${teamId}`)
    
    if (savedGameRoster) {
      setDefaultGameRoster(JSON.parse(savedGameRoster))
    }
    if (savedStartingFive) {
      setDefaultStartingFive(JSON.parse(savedStartingFive))
    }
  }, [teamId, fetchTeam, fetchTeamMembers, fetchAvailableJerseyNumbers])

  // Save default roster to localStorage
  const saveDefaultRoster = () => {
    localStorage.setItem(`defaultGameRoster_${teamId}`, JSON.stringify(defaultGameRoster))
    localStorage.setItem(`defaultStartingFive_${teamId}`, JSON.stringify(defaultStartingFive))
    setIsEditingRoster(false)
  }

  // Handle roster selection
  const handleRosterSelection = (playerId: number, type: 'gameRoster' | 'startingFive', checked: boolean) => {
    if (type === 'gameRoster') {
      if (checked) {
        if (defaultGameRoster.length < 12) {
          setDefaultGameRoster(prev => [...prev, playerId])
        }
      } else {
        setDefaultGameRoster(prev => prev.filter(id => id !== playerId))
        // Remove from starting five if present
        setDefaultStartingFive(prev => prev.filter(id => id !== playerId))
      }
    } else if (type === 'startingFive') {
      if (checked) {
        if (defaultStartingFive.length < 5 && defaultGameRoster.includes(playerId)) {
          setDefaultStartingFive(prev => [...prev, playerId])
        }
      } else {
        setDefaultStartingFive(prev => prev.filter(id => id !== playerId))
      }
    }
  }

  const players = useMemo(() => (currentTeam?.players ?? []).slice().sort((a, b) => {
    const na = a.jersey_number ?? 1000
    const nb = b.jersey_number ?? 1000
    if (na === nb) return `${a.first_name ?? ''}${a.last_name ?? ''}`.localeCompare(`${b.first_name ?? ''}${b.last_name ?? ''}`)
    return na - nb
  }), [currentTeam])
  const coaches = useMemo(() => (currentTeam?.coaches ?? []).slice().sort((a, b) => {
    if (a.coach_type === 'HEAD_COACH' && b.coach_type !== 'HEAD_COACH') return -1
    if (a.coach_type !== 'HEAD_COACH' && b.coach_type === 'HEAD_COACH') return 1
    return 0
  }), [currentTeam])
  const staff = currentTeam?.staff ?? []

  const onRemove = async (userId: number, r: Role) => {
    if (!teamId) return
    await removeMemberFromTeam(teamId, userId, r)
  }

  const openAdd = (targetRole: Role) => {
    setRole(targetRole)
    setAddMode('new')
    setForm({})
    setSelectedExistingId(null)
    clearSearchResults()
    setIsAddOpen(true)
  }

  const submitAdd = async () => {
    if (!teamId) return
    if (addMode === 'existing') {
      if (!selectedExistingId) return
      await addMemberToTeam(teamId, selectedExistingId, role, form['staff_type'])
      setIsAddOpen(false)
      return
    }

    if (role === 'PLAYER') {
      await createAndAddPlayer(teamId, {
        username: form['username'] ?? '',
        email: form['email'] ?? '',
        first_name: form['first_name'] || undefined,
        last_name: form['last_name'] || undefined,
        jersey_number: form['jersey_number'] ? Number(form['jersey_number']) : undefined,
      })
    } else if (role === 'COACH') {
      await createAndAddCoach(teamId, {
        username: form['username'] ?? '',
        email: form['email'] ?? '',
        first_name: form['first_name'] || undefined,
        last_name: form['last_name'] || undefined,
        coach_type: (form['coach_type'] as string) || 'ASSISTANT_COACH',
      })
    } else {
      await createAndAddStaff(teamId, {
        username: form['username'] ?? '',
        email: form['email'] ?? '',
        first_name: form['first_name'] || undefined,
        last_name: form['last_name'] || undefined,
        staff_type: (form['staff_type'] as string) || 'PHYSIO',
      })
    }
    setIsAddOpen(false)
  }

  const displayName = (m: { first_name?: string; last_name?: string; username: string }) =>
    m.first_name && m.last_name ? `${m.first_name} ${m.last_name}` : m.username

  return (
    <div className="animate-fade-in">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Manage Roster</h1>
          <p className="text-gray-600 dark:text-gray-400">{currentTeam?.name}</p>
        </div>
        <button
          className="inline-flex items-center px-4 py-2 rounded-md bg-gray-800 text-white hover:bg-gray-700"
          onClick={() => navigate(`/teams/${teamId}`)}
        >Back to Team</button>
      </div>

      {error && (
        <div className="mb-4 rounded border border-red-300 bg-red-50 p-3 text-sm text-red-800">
          {error}
          <button className="ml-3 underline" onClick={clearError}>dismiss</button>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <section className="bg-white dark:bg-gray-800 rounded shadow p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-900 dark:text-white">Coaches</h2>
            <button className="text-sm text-blue-600" onClick={() => openAdd('COACH')}>Add coach</button>
          </div>
          {coaches.length === 0 ? (
            <p className="text-sm text-gray-500">No coaches</p>
          ) : (
            <ul className="divide-y divide-gray-200 dark:divide-gray-700">
              {coaches.map(c => (
                <li key={c.id} className="py-2 flex items-center justify-between">
                  <div>
                    <div className="font-medium text-gray-900 dark:text-white">{displayName(c)}</div>
                    <div className="text-xs text-gray-500">{c.coach_type || 'COACH'}</div>
                  </div>
                  <button className="text-red-600 text-sm" onClick={() => onRemove(c.id, 'COACH')}>Remove</button>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="bg-white dark:bg-gray-800 rounded shadow p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-900 dark:text-white">Staff</h2>
            <button className="text-sm text-blue-600" onClick={() => openAdd('STAFF')}>Add staff</button>
          </div>
          {staff.length === 0 ? (
            <p className="text-sm text-gray-500">No staff</p>
          ) : (
            <ul className="divide-y divide-gray-200 dark:divide-gray-700">
              {staff.map(s => (
                <li key={s.id} className="py-2 flex items-center justify-between">
                  <div>
                    <div className="font-medium text-gray-900 dark:text-white">{displayName(s)}</div>
                    <div className="text-xs text-gray-500">{s.staff_type || 'STAFF'}</div>
                  </div>
                  <button className="text-red-600 text-sm" onClick={() => onRemove(s.id, 'STAFF')}>Remove</button>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="bg-white dark:bg-gray-800 rounded shadow p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-900 dark:text-white">Players</h2>
            <button className="text-sm text-blue-600" onClick={() => openAdd('PLAYER')}>Add player</button>
          </div>
          {players.length === 0 ? (
            <p className="text-sm text-gray-500">No players</p>
          ) : (
            <ul className="divide-y divide-gray-200 dark:divide-gray-700">
              {players.map(p => (
                <li key={p.id} className="py-2 flex items-center justify-between">
                  <div>
                    <div className="font-medium text-gray-900 dark:text-white">{displayName(p)}</div>
                    <div className="text-xs text-gray-500">#{p.jersey_number ?? '—'}</div>
                  </div>
                  <button className="text-red-600 text-sm" onClick={() => onRemove(p.id, 'PLAYER')}>Remove</button>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      {/* Default Roster Management */}
      <div className="mt-8 bg-white dark:bg-gray-800 rounded shadow p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white flex items-center">
              <UserGroupIcon className="h-6 w-6 mr-2" />
              Default Game Roster
            </h2>
            <p className="text-gray-600 dark:text-gray-400 text-sm mt-1">
              Set your default 12-player game roster and starting five. This will be auto-populated in game setup.
            </p>
          </div>
          <div className="flex gap-2">
            {isEditingRoster ? (
              <>
                <button
                  onClick={() => setIsEditingRoster(false)}
                  className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={saveDefaultRoster}
                  className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors flex items-center"
                >
                  <CheckCircleIcon className="h-4 w-4 mr-2" />
                  Save Roster
                </button>
              </>
            ) : (
              <button
                onClick={() => setIsEditingRoster(true)}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors flex items-center"
              >
                <PencilIcon className="h-4 w-4 mr-2" />
                Edit Roster
              </button>
            )}
          </div>
        </div>

        {isEditingRoster ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Game Roster Selection */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-3">
                Game Roster ({defaultGameRoster.length}/12)
              </h3>
              <div className="space-y-2 max-h-96 overflow-y-auto border rounded-lg p-3">
                {players.map((player) => (
                  <label key={player.id} className="flex items-center p-2 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={defaultGameRoster.includes(player.id)}
                      onChange={(e) => handleRosterSelection(player.id, 'gameRoster', e.target.checked)}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                      disabled={!defaultGameRoster.includes(player.id) && defaultGameRoster.length >= 12}
                    />
                    <div className="ml-3 flex-1">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium text-gray-900">
                          #{player.jersey_number} {player.first_name} {player.last_name}
                        </span>
                        <span className="text-xs text-gray-500">Player</span>
                      </div>
                    </div>
                  </label>
                ))}
              </div>
            </div>

            {/* Starting Five Selection */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-3">
                Starting Five ({defaultStartingFive.length}/5)
              </h3>
              <div className="space-y-2 max-h-96 overflow-y-auto border rounded-lg p-3">
                {players
                  .filter(player => defaultGameRoster.includes(player.id))
                  .map((player) => (
                    <label key={player.id} className="flex items-center p-2 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={defaultStartingFive.includes(player.id)}
                        onChange={(e) => handleRosterSelection(player.id, 'startingFive', e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        disabled={!defaultStartingFive.includes(player.id) && defaultStartingFive.length >= 5}
                      />
                      <div className="ml-3 flex-1">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="text-xs text-gray-500">Player</span>
                        </div>
                      </div>
                    </label>
                  ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Current Game Roster Display */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-3">
                Current Game Roster ({defaultGameRoster.length}/12)
              </h3>
              <div className="space-y-2">
                {defaultGameRoster.length > 0 ? (
                  players
                    .filter(player => defaultGameRoster.includes(player.id))
                    .map((player) => (
                      <div key={player.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="ml-2 text-xs text-gray-500">Player</span>
                        </div>
                        {defaultStartingFive.includes(player.id) && (
                          <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full">
                            Starting
                          </span>
                        )}
                      </div>
                    ))
                ) : (
                  <p className="text-sm text-gray-500 italic">No default roster set</p>
                )}
              </div>
            </div>

            {/* Current Starting Five Display */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-3">
                Current Starting Five ({defaultStartingFive.length}/5)
              </h3>
              <div className="space-y-2">
                {defaultStartingFive.length > 0 ? (
                  players
                    .filter(player => defaultStartingFive.includes(player.id))
                    .map((player) => (
                      <div key={player.id} className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                        <div className="flex items-center">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="ml-2 text-xs text-gray-500">Player</span>
                        </div>
                        <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full">
                          Starting
                        </span>
                      </div>
                    ))
                ) : (
                  <p className="text-sm text-gray-500 italic">No default starting five set</p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {isAddOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-lg rounded bg-white dark:bg-gray-900 p-4 shadow">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-gray-900 dark:text-white">Add {role.toLowerCase()}</h3>
              <button className="text-sm" onClick={() => setIsAddOpen(false)}>Close</button>
            </div>

            <div className="mb-3 flex gap-2">
              <button
                className={`px-3 py-1 rounded border ${addMode === 'new' ? 'bg-gray-800 text-white' : 'bg-white dark:bg-gray-800 text-gray-700'}`}
                onClick={() => setAddMode('new')}
              >Create new</button>
              <button
                className={`px-3 py-1 rounded border ${addMode === 'existing' ? 'bg-gray-800 text-white' : 'bg-white dark:bg-gray-800 text-gray-700'}`}
                onClick={() => setAddMode('existing')}
              >Select existing</button>
            </div>

            {addMode === 'existing' ? (
              <div>
                <div className="mb-2">
                  <input
                    className="w-full rounded border px-3 py-2 bg-white dark:bg-gray-800"
                    placeholder={`Search ${role.toLowerCase()}s...`}
                    onChange={(e) => searchUsers(e.target.value, role)}
                  />
                </div>
                <div className="max-h-60 overflow-y-auto border rounded">
                  {(searchResults || []).map(u => (
                    <label key={u.id} className="flex items-center justify-between px-3 py-2 border-b last:border-b-0">
                      <div>
                        <div className="text-sm font-medium">{displayName(u)}</div>
                        <div className="text-xs text-gray-500">@{u.username}</div>
                      </div>
                      <input
                        type="radio"
                        name="existing"
                        value={u.id}
                        checked={selectedExistingId === u.id}
                        onChange={() => setSelectedExistingId(u.id)}
                      />
                    </label>
                  ))}
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input className="rounded border px-3 py-2 bg-white dark:bg-gray-800" placeholder="Username *" onChange={e => setForm(f => ({ ...f, username: e.target.value }))} />
                <input className="rounded border px-3 py-2 bg-white dark:bg-gray-800" placeholder="Email *" onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
                <input className="rounded border px-3 py-2 bg-white dark:bg-gray-800" placeholder="First name" onChange={e => setForm(f => ({ ...f, first_name: e.target.value }))} />
                <input className="rounded border px-3 py-2 bg-white dark:bg-gray-800" placeholder="Last name" onChange={e => setForm(f => ({ ...f, last_name: e.target.value }))} />

                {role === 'PLAYER' && (
                  <select
                    className="rounded border px-3 py-2 bg-white dark:bg-gray-800"
                    onChange={e => setForm(f => ({ ...f, jersey_number: e.target.value }))}
                    defaultValue=""
                  >
                    <option value="" disabled>Jersey number</option>
                    {(availableJerseyNumbers?.available_numbers ?? []).map(n => (
                      <option key={n} value={n}>{n}</option>
                    ))}
                  </select>
                )}

                {role === 'COACH' && (
                  <select
                    className="rounded border px-3 py-2 bg-white dark:bg-gray-800"
                    onChange={e => setForm(f => ({ ...f, coach_type: e.target.value }))}
                    defaultValue="ASSISTANT_COACH"
                  >
                    <option value="HEAD_COACH">HEAD_COACH</option>
                    <option value="ASSISTANT_COACH">ASSISTANT_COACH</option>
                  </select>
                )}

                {role === 'STAFF' && (
                  <select
                    className="rounded border px-3 py-2 bg-white dark:bg-gray-800"
                    onChange={e => setForm(f => ({ ...f, staff_type: e.target.value }))}
                    defaultValue="PHYSIO"
                  >
                    <option value="PHYSIO">PHYSIO</option>
                    <option value="STRENGTH_CONDITIONING">STRENGTH_CONDITIONING</option>
                    <option value="MANAGEMENT">MANAGEMENT</option>
                  </select>
                )}
              </div>
            )}

            <div className="mt-4 flex items-center justify-end gap-2">
              <button className="px-4 py-2 rounded border" onClick={() => setIsAddOpen(false)}>Cancel</button>
              <button className="px-4 py-2 rounded bg-blue-600 text-white disabled:opacity-60" disabled={isLoading} onClick={submitAdd}>
                {isLoading ? 'Saving...' : 'Add'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}


