import { useEffect, useMemo, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { possessionsApi } from '../../services/api'
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'

type Possession = {
  id: number
  game?: number
  play_type?: string
  outcome?: string
  points?: number
  period?: number
  time?: string
}

export function GameStats() {
  const { gameId } = useParams()
  const [list, setList] = useState<Possession[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const load = async () => {
      if (!gameId) return
      setLoading(true)
      setError(null)
      try {
        const data = await possessionsApi.getPossessions({ game_id: gameId })
        const arr = Array.isArray((data as any)) ? (data as any) : (data as any)?.results || []
        setList(arr as Possession[])
      } catch (e: any) {
        setError(e?.message || 'Failed to load possessions')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [gameId])

  const summary = useMemo(() => {
    const total = list.length
    const points = list.reduce((s, p) => s + (typeof p.points === 'number' ? p.points : 0), 0)
    const byOutcome: Record<string, number> = {}
    const byPlayType: Record<string, number> = {}
    list.forEach(p => {
      if (p.outcome) byOutcome[p.outcome] = (byOutcome[p.outcome] || 0) + 1
      if (p.play_type) byPlayType[p.play_type] = (byPlayType[p.play_type] || 0) + 1
    })
    return { total, points, ppp: total ? (points / total).toFixed(3) : '0.000', byOutcome, byPlayType }
  }, [list])

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Game Stats</h1>
        <div className="flex gap-2">
          <Link to={`/games/${gameId}`}><Button variant="outline">Details</Button></Link>
          <Link to={`/games/${gameId}/track`}><Button>Track</Button></Link>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Summary</CardTitle>
        </CardHeader>
        <CardContent>
          {loading && <div className="text-gray-600 dark:text-gray-400">Loading…</div>}
          {error && <div className="text-red-600 dark:text-red-400">{error}</div>}
          {!loading && !error && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 rounded-xl bg-white/80 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-700">
                <div className="text-sm text-gray-600 dark:text-gray-400">Possessions</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white">{summary.total}</div>
              </div>
              <div className="p-4 rounded-xl bg-white/80 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-700">
                <div className="text-sm text-gray-600 dark:text-gray-400">Points</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white">{summary.points}</div>
              </div>
              <div className="p-4 rounded-xl bg-white/80 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-700">
                <div className="text-sm text-gray-600 dark:text-gray-400">PPP</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white">{summary.ppp}</div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Breakdowns</CardTitle>
        </CardHeader>
        <CardContent>
          {!loading && !error && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div className="font-medium text-gray-900 dark:text-white mb-2">By Outcome</div>
                <ul className="text-sm text-gray-700 dark:text-gray-300 space-y-1">
                  {Object.keys(summary.byOutcome).length === 0 && <li>—</li>}
                  {Object.entries(summary.byOutcome).map(([k, v]) => (
                    <li key={k}>{k}: {v}</li>
                  ))}
                </ul>
              </div>
              <div>
                <div className="font-medium text-gray-900 dark:text-white mb-2">By Play Type</div>
                <ul className="text-sm text-gray-700 dark:text-gray-300 space-y-1">
                  {Object.keys(summary.byPlayType).length === 0 && <li>—</li>}
                  {Object.entries(summary.byPlayType).map(([k, v]) => (
                    <li key={k}>{k}: {v}</li>
                  ))}
                </ul>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}


