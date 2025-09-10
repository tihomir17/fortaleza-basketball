// Mock data service for testing frontend when backend is unavailable
export const mockDashboardData = {
  quickStats: {
    totalGames: 24,
    wins: 18,
    losses: 6,
    winPercentage: 75.0,
    upcomingGames: 3,
    activePlayers: 12
  },
  upcomingGames: [
    {
      id: 1,
      home_team_name: 'Fortaleza',
      away_team_name: 'Lakers',
      date: '2024-01-15',
      time: '19:00',
      venue: 'Home Court'
    },
    {
      id: 2,
      home_team_name: 'Warriors',
      away_team_name: 'Fortaleza',
      date: '2024-01-18',
      time: '20:30',
      venue: 'Away Court'
    },
    {
      id: 3,
      home_team_name: 'Fortaleza',
      away_team_name: 'Celtics',
      date: '2024-01-22',
      time: '19:30',
      venue: 'Home Court'
    }
  ],
  recentGames: [
    {
      id: 4,
      home_team_name: 'Fortaleza',
      away_team_name: 'Heat',
      home_score: 98,
      away_score: 92,
      date: '2024-01-10',
      result: 'W'
    },
    {
      id: 5,
      home_team_name: 'Nuggets',
      away_team_name: 'Fortaleza',
      home_score: 105,
      away_score: 98,
      date: '2024-01-08',
      result: 'L'
    },
    {
      id: 6,
      home_team_name: 'Fortaleza',
      away_team_name: 'Suns',
      home_score: 112,
      away_score: 108,
      date: '2024-01-05',
      result: 'W'
    }
  ],
  topPerformers: [
    {
      player_name: 'John Smith',
      jersey_number: 23,
      points_per_game: 24.5,
      rebounds_per_game: 8.2,
      assists_per_game: 6.1
    },
    {
      player_name: 'Mike Johnson',
      jersey_number: 7,
      points_per_game: 19.8,
      rebounds_per_game: 6.5,
      assists_per_game: 4.2
    },
    {
      player_name: 'David Wilson',
      jersey_number: 15,
      points_per_game: 16.2,
      rebounds_per_game: 9.1,
      assists_per_game: 2.8
    },
    {
      player_name: 'Chris Brown',
      jersey_number: 3,
      points_per_game: 14.7,
      rebounds_per_game: 5.3,
      assists_per_game: 7.4
    }
  ],
  recentActivity: [
    {
      id: 1,
      type: 'GAME',
      message: 'Game against Heat completed - Win 98-92',
      timestamp: '2024-01-10T21:30:00Z'
    },
    {
      id: 2,
      type: 'PLAYER',
      message: 'John Smith scored season-high 35 points',
      timestamp: '2024-01-10T21:15:00Z'
    },
    {
      id: 3,
      type: 'TEAM',
      message: 'Team practice scheduled for tomorrow at 10 AM',
      timestamp: '2024-01-10T18:00:00Z'
    },
    {
      id: 4,
      type: 'SCOUTING',
      message: 'Lakers scouting report updated',
      timestamp: '2024-01-10T16:30:00Z'
    }
  ],
  lastUpdated: new Date().toISOString()
}

export const mockGamesData = [
  {
    id: 1,
    home_team: { name: 'Fortaleza' },
    away_team: { name: 'Lakers' },
    game_date: '2024-01-15T19:00:00Z',
    home_team_score: null,
    away_team_score: null,
    status: 'SCHEDULED',
    venue: 'Home Court'
  },
  {
    id: 2,
    home_team: { name: 'Warriors' },
    away_team: { name: 'Fortaleza' },
    game_date: '2024-01-18T20:30:00Z',
    home_team_score: null,
    away_team_score: null,
    status: 'SCHEDULED',
    venue: 'Away Court'
  },
  {
    id: 3,
    home_team: { name: 'Fortaleza' },
    away_team: { name: 'Celtics' },
    game_date: '2024-01-22T19:30:00Z',
    home_team_score: null,
    away_team_score: null,
    status: 'SCHEDULED',
    venue: 'Home Court'
  },
  {
    id: 4,
    home_team: { name: 'Fortaleza' },
    away_team: { name: 'Heat' },
    game_date: '2024-01-10T19:00:00Z',
    home_team_score: 98,
    away_team_score: 92,
    status: 'COMPLETED',
    venue: 'Home Court'
  },
  {
    id: 5,
    home_team: { name: 'Nuggets' },
    away_team: { name: 'Fortaleza' },
    game_date: '2024-01-08T20:00:00Z',
    home_team_score: 105,
    away_team_score: 98,
    status: 'COMPLETED',
    venue: 'Away Court'
  }
]

export const mockScoutingReports = [
  {
    id: 1,
    opponent: 'Lakers',
    date: '2024-01-15',
    status: 'COMPLETED',
    priority: 'HIGH',
    lastUpdated: '2024-01-10',
    createdBy: 'Coach Smith',
    notes: 'Strong perimeter shooting team with excellent ball movement.',
    keyPlayers: [
      {
        name: 'LeBron James',
        position: 'SF',
        strengths: ['Leadership', 'Versatility', 'Basketball IQ'],
        weaknesses: ['Age', 'Defensive consistency']
      },
      {
        name: 'Anthony Davis',
        position: 'PF',
        strengths: ['Shot blocking', 'Post scoring', 'Rebounding'],
        weaknesses: ['Injury prone', 'Free throw shooting']
      }
    ],
    teamTendencies: {
      offense: ['Pick and roll', 'Fast break', 'Three-point shooting'],
      defense: ['Zone defense', 'Full court press'],
      specialSituations: ['Late game execution', 'Free throw shooting']
    }
  },
  {
    id: 2,
    opponent: 'Warriors',
    date: '2024-01-20',
    status: 'DRAFT',
    priority: 'MEDIUM',
    lastUpdated: '2024-01-12',
    createdBy: 'Assistant Coach',
    notes: 'High-paced offense with excellent three-point shooting.',
    keyPlayers: [
      {
        name: 'Stephen Curry',
        position: 'PG',
        strengths: ['Three-point shooting', 'Ball handling', 'Leadership'],
        weaknesses: ['Size', 'Defensive matchups']
      }
    ],
    teamTendencies: {
      offense: ['Three-point shooting', 'Ball movement', 'Fast pace'],
      defense: ['Switch everything', 'Help defense'],
      specialSituations: ['Clutch shooting', 'Timeout execution']
    }
  }
]

// Helper function to simulate API delay
export const simulateApiDelay = (ms: number = 500) => 
  new Promise(resolve => setTimeout(resolve, ms))

// Helper function to simulate API errors
export const simulateApiError = (message: string = 'Mock API Error') => 
  Promise.reject(new Error(message))

// Mock Analytics Data
export const mockAnalyticsData = {
  summary: {
    total_games: 24,
    total_wins: 18,
    total_losses: 6,
    win_percentage: 75.0,
    average_points_for: 98.5,
    average_points_against: 92.3,
    average_point_differential: 6.2,
    average_pace: 95.2,
    average_offensive_efficiency: 108.5,
    average_defensive_efficiency: 102.3,
    average_net_efficiency: 6.2
  },
  trends: {
    recent_form: ['W', 'W', 'L', 'W', 'L', 'W', 'W', 'L', 'W', 'W'],
    points_trend: [95, 102, 98, 105, 99, 101, 98, 89, 102, 94],
    efficiency_trend: [7.0, 8.0, 7.0, 8.0, 6.0, 6.0, 6.2, -6.0, 14.0, -7.0],
    pace_trend: [95.1, 95.3, 95.0, 95.4, 95.2, 95.1, 94.2, 96.1, 93.5, 95.8]
  },
  team_stats: {
    team_id: 1,
    team_name: 'Fortaleza',
    games_played: 24,
    wins: 18,
    losses: 6,
    win_percentage: 75.0,
    points_for: 2364,
    points_against: 2215,
    point_differential: 149,
    possessions: 1200,
    pace: 95.2,
    offensive_efficiency: 108.5,
    defensive_efficiency: 102.3,
    net_efficiency: 6.2,
    field_goal_percentage: 46.8,
    three_point_percentage: 36.2,
    free_throw_percentage: 78.5,
    rebounds: 45.2,
    assists: 22.1,
    turnovers: 14.3,
    steals: 8.7,
    blocks: 4.2
  },
  game_analytics: [
    {
      game_id: 1,
      game_date: '2024-01-15',
      home_team: 'Fortaleza',
      away_team: 'Lakers',
      home_score: 98,
      away_score: 92,
      outcome: 'W',
      possessions: 95,
      pace: 94.2,
      offensive_efficiency: 103.2,
      defensive_efficiency: 96.8,
      field_goal_percentage: 47.8,
      three_point_percentage: 38.5,
      free_throw_percentage: 82.1,
      rebounds: 44,
      assists: 23,
      turnovers: 12,
      steals: 8,
      blocks: 4
    },
    {
      game_id: 2,
      game_date: '2024-01-18',
      home_team: 'Warriors',
      away_team: 'Fortaleza',
      home_score: 98,
      away_score: 105,
      outcome: 'W',
      possessions: 98,
      pace: 96.1,
      offensive_efficiency: 107.1,
      defensive_efficiency: 100.0,
      field_goal_percentage: 49.2,
      three_point_percentage: 41.3,
      free_throw_percentage: 85.7,
      rebounds: 46,
      assists: 25,
      turnovers: 14,
      steals: 9,
      blocks: 5
    },
    {
      game_id: 3,
      game_date: '2024-01-22',
      home_team: 'Fortaleza',
      away_team: 'Celtics',
      home_score: 89,
      away_score: 95,
      outcome: 'L',
      possessions: 92,
      pace: 93.5,
      offensive_efficiency: 96.7,
      defensive_efficiency: 103.3,
      field_goal_percentage: 44.1,
      three_point_percentage: 35.2,
      free_throw_percentage: 78.9,
      rebounds: 42,
      assists: 20,
      turnovers: 16,
      steals: 6,
      blocks: 3
    },
    {
      game_id: 4,
      game_date: '2024-01-25',
      home_team: 'Heat',
      away_team: 'Fortaleza',
      home_score: 88,
      away_score: 102,
      outcome: 'W',
      possessions: 96,
      pace: 95.8,
      offensive_efficiency: 106.3,
      defensive_efficiency: 91.7,
      field_goal_percentage: 51.3,
      three_point_percentage: 39.8,
      free_throw_percentage: 83.3,
      rebounds: 48,
      assists: 27,
      turnovers: 11,
      steals: 10,
      blocks: 6
    },
    {
      game_id: 5,
      game_date: '2024-01-28',
      home_team: 'Fortaleza',
      away_team: 'Nuggets',
      home_score: 94,
      away_score: 101,
      outcome: 'L',
      possessions: 94,
      pace: 94.7,
      offensive_efficiency: 100.0,
      defensive_efficiency: 107.4,
      field_goal_percentage: 45.8,
      three_point_percentage: 36.7,
      free_throw_percentage: 80.0,
      rebounds: 43,
      assists: 22,
      turnovers: 15,
      steals: 7,
      blocks: 4
    }
  ],
  player_stats: [
    {
      id: 1,
      username: 'jsmith',
      first_name: 'John',
      last_name: 'Smith',
      jersey_number: 10,
      role: 'PG',
      games_played: 24,
      possessions: 780,
      points: 588,
      assists: 146,
      rebounds: 197,
      steals: 43,
      blocks: 12,
      turnovers: 89,
      field_goals_made: 220,
      field_goals_attempted: 456,
      three_pointers_made: 65,
      three_pointers_attempted: 169,
      free_throws_made: 83,
      free_throws_attempted: 97,
      field_goal_percentage: 48.2,
      three_point_percentage: 38.5,
      free_throw_percentage: 85.7,
      points_per_game: 24.5,
      assists_per_game: 6.1,
      rebounds_per_game: 8.2,
      steals_per_game: 1.8,
      blocks_per_game: 0.5,
      turnovers_per_game: 3.7,
      efficiency_rating: 18.3,
      plus_minus: 156
    },
    {
      id: 2,
      username: 'mjohnson',
      first_name: 'Mike',
      last_name: 'Johnson',
      jersey_number: 7,
      role: 'SG',
      games_played: 24,
      possessions: 680,
      points: 475,
      assists: 101,
      rebounds: 156,
      steals: 29,
      blocks: 7,
      turnovers: 78,
      field_goals_made: 180,
      field_goals_attempted: 393,
      three_pointers_made: 85,
      three_pointers_attempted: 202,
      free_throws_made: 30,
      free_throws_attempted: 36,
      field_goal_percentage: 45.8,
      three_point_percentage: 42.1,
      free_throw_percentage: 82.3,
      points_per_game: 19.8,
      assists_per_game: 4.2,
      rebounds_per_game: 6.5,
      steals_per_game: 1.2,
      blocks_per_game: 0.3,
      turnovers_per_game: 3.3,
      efficiency_rating: 15.1,
      plus_minus: 89
    },
    {
      id: 3,
      username: 'dwilson',
      first_name: 'David',
      last_name: 'Wilson',
      jersey_number: 23,
      role: 'SF',
      games_played: 24,
      possessions: 722,
      points: 389,
      assists: 67,
      rebounds: 218,
      steals: 36,
      blocks: 29,
      turnovers: 65,
      field_goals_made: 150,
      field_goals_attempted: 287,
      three_pointers_made: 45,
      three_pointers_attempted: 126,
      free_throws_made: 44,
      free_throws_attempted: 56,
      field_goal_percentage: 52.3,
      three_point_percentage: 35.8,
      free_throw_percentage: 78.9,
      points_per_game: 16.2,
      assists_per_game: 2.8,
      rebounds_per_game: 9.1,
      steals_per_game: 1.5,
      blocks_per_game: 1.2,
      turnovers_per_game: 2.7,
      efficiency_rating: 14.7,
      plus_minus: 67
    },
    {
      id: 4,
      username: 'cbrown',
      first_name: 'Chris',
      last_name: 'Brown',
      jersey_number: 15,
      role: 'PF',
      games_played: 24,
      possessions: 643,
      points: 353,
      assists: 178,
      rebounds: 127,
      steals: 22,
      blocks: 19,
      turnovers: 58,
      field_goals_made: 130,
      field_goals_attempted: 278,
      three_pointers_made: 25,
      three_pointers_attempted: 75,
      free_throws_made: 68,
      free_throws_attempted: 83,
      field_goal_percentage: 46.7,
      three_point_percentage: 33.2,
      free_throw_percentage: 81.5,
      points_per_game: 14.7,
      assists_per_game: 7.4,
      rebounds_per_game: 5.3,
      steals_per_game: 0.9,
      blocks_per_game: 0.8,
      turnovers_per_game: 2.4,
      efficiency_rating: 13.9,
      plus_minus: 45
    },
    {
      id: 5,
      username: 'adavis',
      first_name: 'Alex',
      last_name: 'Davis',
      jersey_number: 42,
      role: 'C',
      games_played: 24,
      possessions: 588,
      points: 295,
      assists: 46,
      rebounds: 283,
      steals: 17,
      blocks: 50,
      turnovers: 52,
      field_goals_made: 120,
      field_goals_attempted: 205,
      three_pointers_made: 0,
      three_pointers_attempted: 0,
      free_throws_made: 55,
      free_throws_attempted: 76,
      field_goal_percentage: 58.4,
      three_point_percentage: 0.0,
      free_throw_percentage: 72.1,
      points_per_game: 12.3,
      assists_per_game: 1.9,
      rebounds_per_game: 11.8,
      steals_per_game: 0.7,
      blocks_per_game: 2.1,
      turnovers_per_game: 2.2,
      efficiency_rating: 12.8,
      plus_minus: 23
    }
  ]
}