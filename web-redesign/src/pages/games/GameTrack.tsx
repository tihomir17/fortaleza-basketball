import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { possessionsApi } from '../../services/api'
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'

export function GameTrack() {
  const { gameId } = useParams()
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    play_type: 'PICK_AND_ROLL',
    outcome: 'MISS',
    points: 0,
    period: 1,
    time: ''
  })

  const save = async () => {
    if (!gameId) return
    setSaving(true)
    setError(null)
    try {
      await possessionsApi.createPossession({
        game: Number(gameId),
        play_type: form.play_type,
        outcome: form.outcome,
        points: Number(form.points) || 0,
        period: Number(form.period) || 1,
        time: form.time || undefined,
      })
      setForm({ play_type: 'PICK_AND_ROLL', outcome: 'MISS', points: 0, period: 1, time: '' })
    } catch (e: any) {
      setError(e?.message || 'Failed to save possession')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Live Tracking</h1>
        <div className="flex gap-2">
          <Link to={`/games/${gameId}`}><Button variant="outline">Details</Button></Link>
          <Link to={`/games/${gameId}/stats`}><Button variant="outline">Stats</Button></Link>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add Possession</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={form.play_type}
                    onChange={e => setForm(f => ({ ...f, play_type: e.target.value }))}>
              <option value="PICK_AND_ROLL">Pick & Roll</option>
              <option value="ISOLATION">Isolation</option>
              <option value="TRANSITION">Transition</option>
              <option value="POST_UP">Post-up</option>
              <option value="SPOT_UP">Spot-up</option>
            </select>
            <select className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2"
                    value={form.outcome}
                    onChange={e => setForm(f => ({ ...f, outcome: e.target.value }))}>
              <option value="MAKE">Make</option>
              <option value="MISS">Miss</option>
              <option value="TURNOVER">Turnover</option>
              <option value="FOUL">Foul</option>
              <option value="REBOUND">Rebound</option>
            </select>
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Points"
                   value={form.points}
                   onChange={e => setForm(f => ({ ...f, points: e.target.value as any }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2" placeholder="Period"
                   value={form.period}
                   onChange={e => setForm(f => ({ ...f, period: e.target.value as any }))} />
            <input className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 md:col-span-2" placeholder="Time (MM:SS)"
                   value={form.time}
                   onChange={e => setForm(f => ({ ...f, time: e.target.value }))} />
          </div>
          <div className="mt-3">
            <Button onClick={save} loading={saving}>Save Possession</Button>
            {error && <span className="ml-3 text-sm text-red-600 dark:text-red-400">{error}</span>}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}


