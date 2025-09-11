import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CalendarIcon, ClockIcon, MapPinIcon, UsersIcon } from '@heroicons/react/24/outline'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Select } from '../../components/ui/Select'
import { Textarea } from '../../components/ui/Textarea'
import { Card } from '../../components/ui/Card'

interface GameScheduleForm {
  opponent: string
  date: string
  time: string
  location: string
  competition: string
  notes: string
  teamId: string
}

export function GameSchedule() {
  const navigate = useNavigate()
  const [form, setForm] = useState<GameScheduleForm>({
    opponent: '',
    date: '',
    time: '',
    location: '',
    competition: '',
    notes: '',
    teamId: ''
  })
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    
    try {
      // TODO: Implement API call to schedule game
      console.log('Scheduling game:', form)
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // Navigate back to games list
      navigate('/games')
    } catch (error) {
      console.error('Error scheduling game:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleInputChange = (field: keyof GameScheduleForm, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="max-w-2xl mx-auto p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Schedule Game</h1>
        <p className="text-gray-600">Create a new game and add it to your schedule</p>
      </div>

      <Card>
        <form onSubmit={handleSubmit} className="space-y-6 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="opponent" className="block text-sm font-medium text-gray-700 mb-2">
                Opponent Team
              </label>
              <Input
                id="opponent"
                type="text"
                value={form.opponent}
                onChange={(e) => handleInputChange('opponent', e.target.value)}
                placeholder="Enter opponent team name"
                required
              />
            </div>

            <div>
              <label htmlFor="teamId" className="block text-sm font-medium text-gray-700 mb-2">
                Your Team
              </label>
              <Select
                id="teamId"
                value={form.teamId}
                onChange={(e) => handleInputChange('teamId', e.target.value)}
                required
              >
                <option value="">Select your team</option>
                <option value="1">Fortaleza Basketball</option>
                <option value="2">Team B</option>
              </Select>
            </div>

            <div>
              <label htmlFor="date" className="block text-sm font-medium text-gray-700 mb-2">
                <CalendarIcon className="inline w-4 h-4 mr-1" />
                Game Date
              </label>
              <Input
                id="date"
                type="date"
                value={form.date}
                onChange={(e) => handleInputChange('date', e.target.value)}
                required
              />
            </div>

            <div>
              <label htmlFor="time" className="block text-sm font-medium text-gray-700 mb-2">
                <ClockIcon className="inline w-4 h-4 mr-1" />
                Game Time
              </label>
              <Input
                id="time"
                type="time"
                value={form.time}
                onChange={(e) => handleInputChange('time', e.target.value)}
                required
              />
            </div>

            <div>
              <label htmlFor="location" className="block text-sm font-medium text-gray-700 mb-2">
                <MapPinIcon className="inline w-4 h-4 mr-1" />
                Location
              </label>
              <Input
                id="location"
                type="text"
                value={form.location}
                onChange={(e) => handleInputChange('location', e.target.value)}
                placeholder="Enter game location"
                required
              />
            </div>

            <div>
              <label htmlFor="competition" className="block text-sm font-medium text-gray-700 mb-2">
                Competition
              </label>
              <Select
                id="competition"
                value={form.competition}
                onChange={(e) => handleInputChange('competition', e.target.value)}
                required
              >
                <option value="">Select competition</option>
                <option value="league">League Game</option>
                <option value="playoff">Playoff Game</option>
                <option value="friendly">Friendly Match</option>
                <option value="tournament">Tournament</option>
              </Select>
            </div>
          </div>

          <div>
            <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
              Additional Notes
            </label>
            <Textarea
              id="notes"
              value={form.notes}
              onChange={(e) => handleInputChange('notes', e.target.value)}
              placeholder="Any additional information about the game..."
              rows={3}
            />
          </div>

          <div className="flex justify-end space-x-4 pt-6 border-t">
            <Button
              type="button"
              variant="outline"
              onClick={() => navigate('/games')}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isSubmitting}
              className="min-w-[120px]"
            >
              {isSubmitting ? 'Scheduling...' : 'Schedule Game'}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  )
}
