import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { gamesApi } from '../../services/api'
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'

export function GameDetails() {
  const { gameId } = useParams()
  const [game, setGame] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const load = async () => {
      if (!gameId) return
      setLoading(true)
      setError(null)
      try {
        const data = await gamesApi.getGame(gameId)
        setGame(data)
      } catch (e: any) {
        setError(e?.message || 'Failed to load game')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [gameId])

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Game Details</h1>
        <div className="flex gap-2">
          <Link to={`/games/${gameId}/stats`}><Button variant="outline">Stats</Button></Link>
          <Link to={`/games/${gameId}/player-stats`}><Button variant="outline">Player Stats</Button></Link>
          <Link to={`/games/${gameId}/track`}><Button>Track</Button></Link>
          <Link to={`/games/${gameId}/post-game-report`}><Button variant="outline">Post Report</Button></Link>
          <Link to={`/games/${gameId}/advanced-report`}><Button variant="outline">Advanced Report</Button></Link>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Metadata</CardTitle>
        </CardHeader>
        <CardContent>
          {loading && <div className="text-gray-600 dark:text-gray-400">Loading…</div>}
          {error && <div className="text-red-600 dark:text-red-400">{error}</div>}
          {!loading && !error && (
            <pre className="text-sm bg-white/60 dark:bg-gray-800/60 rounded-lg p-3 border border-gray-200 dark:border-gray-700 overflow-auto">
{JSON.stringify(game, null, 2)}
            </pre>
          )}
        </CardContent>
      </Card>
    </div>
  )
}


