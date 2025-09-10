// Mock data for development and demo purposes
export const mockGames = [
  {
    id: 1,
    competition: 1,
    home_team: { id: 1, name: "Fortaleza", logo_url: undefined },
    away_team: { id: 2, name: "Thunder", logo_url: undefined },
    game_date: "2024-12-15T19:00:00Z",
    home_team_score: 0,
    away_team_score: 0,
    quarter: 1,
    lead_changes: 0,
    is_close_game: false,
    is_blowout: false,
    clutch_situations: 0,
    created_at: "2024-12-01T10:00:00Z",
    updated_at: "2024-12-01T10:00:00Z",
    total_possessions: 0,
    offensive_possessions: 0,
    defensive_possessions: 0,
    avg_offensive_possession_time: 0
  },
  {
    id: 2,
    competition: 1,
    home_team: { id: 3, name: "Rivals", logo_url: undefined },
    away_team: { id: 1, name: "Fortaleza", logo_url: undefined },
    game_date: "2024-12-10T20:00:00Z",
    home_team_score: 85,
    away_team_score: 92,
    quarter: 4,
    lead_changes: 3,
    is_close_game: true,
    is_blowout: false,
    clutch_situations: 2,
    created_at: "2024-12-01T10:00:00Z",
    updated_at: "2024-12-10T22:00:00Z",
    total_possessions: 45,
    offensive_possessions: 22,
    defensive_possessions: 23,
    avg_offensive_possession_time: 12.5
  },
  {
    id: 3,
    competition: 1,
    home_team: { id: 1, name: "Fortaleza", logo_url: undefined },
    away_team: { id: 4, name: "Eagles", logo_url: undefined },
    game_date: "2024-12-22T18:30:00Z",
    home_team_score: 0,
    away_team_score: 0,
    quarter: 1,
    lead_changes: 0,
    is_close_game: false,
    is_blowout: false,
    clutch_situations: 0,
    created_at: "2024-12-01T10:00:00Z",
    updated_at: "2024-12-01T10:00:00Z",
    total_possessions: 0,
    offensive_possessions: 0,
    defensive_possessions: 0,
    avg_offensive_possession_time: 0
  }
]

export const mockTeams = [
  {
    id: 1,
    name: "Fortaleza Basketball",
    short_name: "FORT",
    logo: undefined,
    city: "Fortaleza",
    state: "Ceará",
    country: "Brazil",
    founded_year: 2020,
    coach: "Coach Silva",
    assistant_coaches: ["Assistant Coach 1", "Assistant Coach 2"],
    players: []
  },
  {
    id: 2,
    name: "Thunder Basketball",
    short_name: "THUN",
    logo: undefined,
    city: "São Paulo",
    state: "São Paulo",
    country: "Brazil",
    founded_year: 2018,
    coach: "Coach Santos",
    assistant_coaches: ["Assistant Coach A"],
    players: []
  }
]

export const mockPlayers = [
  {
    id: 1,
    first_name: "João",
    last_name: "Silva",
    jersey_number: 10,
    position: "PG" as const,
    height: "6'2\"",
    weight: 180,
    date_of_birth: "1995-03-15",
    team: 1,
    is_active: true,
    stats: {
      games_played: 15,
      points_per_game: 18.5,
      rebounds_per_game: 4.2,
      assists_per_game: 7.8,
      steals_per_game: 1.5,
      blocks_per_game: 0.3,
      field_goal_percentage: 45.2,
      three_point_percentage: 38.7,
      free_throw_percentage: 82.1
    }
  },
  {
    id: 2,
    first_name: "Carlos",
    last_name: "Santos",
    jersey_number: 23,
    position: "SF" as const,
    height: "6'7\"",
    weight: 210,
    date_of_birth: "1992-07-22",
    team: 1,
    is_active: true,
    stats: {
      games_played: 15,
      points_per_game: 22.1,
      rebounds_per_game: 8.3,
      assists_per_game: 3.2,
      steals_per_game: 1.8,
      blocks_per_game: 1.2,
      field_goal_percentage: 48.9,
      three_point_percentage: 35.4,
      free_throw_percentage: 78.5
    }
  },
  {
    id: 3,
    first_name: "Miguel",
    last_name: "Rodriguez",
    jersey_number: 5,
    position: "C" as const,
    height: "6'11\"",
    weight: 245,
    date_of_birth: "1990-11-08",
    team: 1,
    is_active: true,
    stats: {
      games_played: 15,
      points_per_game: 15.8,
      rebounds_per_game: 12.4,
      assists_per_game: 2.1,
      steals_per_game: 0.8,
      blocks_per_game: 2.7,
      field_goal_percentage: 52.3,
      three_point_percentage: 0,
      free_throw_percentage: 71.2
    }
  }
]

export const mockDashboardData = {
  quickStats: {
    totalGames: 15,
    wins: 12,
    losses: 3,
    winPercentage: 80.0,
    upcomingGames: 3,
    activePlayers: 12
  },
  upcomingGames: [
    {
      id: 1,
      home_team_name: "Fortaleza",
      away_team_name: "Thunder",
      date: "2024-12-15",
      time: "19:00",
      venue: "Home Court"
    },
    {
      id: 3,
      home_team_name: "Fortaleza",
      away_team_name: "Eagles",
      date: "2024-12-22",
      time: "18:30",
      venue: "Home Court"
    }
  ],
  recentGames: [
    {
      id: 2,
      home_team_name: "Rivals",
      away_team_name: "Fortaleza",
      home_score: 85,
      away_score: 92,
      date: "2024-12-10",
      result: "W" as const
    }
  ],
  topPerformers: [
    {
      player_name: "Carlos Santos",
      jersey_number: 23,
      points_per_game: 22.1,
      rebounds_per_game: 8.3,
      assists_per_game: 3.2
    },
    {
      player_name: "João Silva",
      jersey_number: 10,
      points_per_game: 18.5,
      rebounds_per_game: 4.2,
      assists_per_game: 7.8
    },
    {
      player_name: "Miguel Rodriguez",
      jersey_number: 5,
      points_per_game: 15.8,
      rebounds_per_game: 12.4,
      assists_per_game: 2.1
    }
  ],
  recentActivity: [
    {
      id: 1,
      type: "GAME" as const,
      message: "Game vs. Rivals completed - Win 92-85",
      timestamp: "2024-12-10T22:30:00Z"
    },
    {
      id: 2,
      type: "PLAYER" as const,
      message: "Carlos Santos scored 25 points in last game",
      timestamp: "2024-12-10T22:15:00Z"
    },
    {
      id: 3,
      type: "TEAM" as const,
      message: "Team roster updated - 2 new players added",
      timestamp: "2024-12-09T14:20:00Z"
    },
    {
      id: 4,
      type: "SCOUTING" as const,
      message: "New scouting report uploaded for Thunder",
      timestamp: "2024-12-08T16:45:00Z"
    }
  ],
  lastUpdated: new Date().toISOString()
}
