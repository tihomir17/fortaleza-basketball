from django.db.models import Q, Count, Avg, Sum, F
from django.db.models.functions import Coalesce
from .models import Game
from apps.possessions.models import Possession


class GameAnalyticsService:
    """Service for calculating comprehensive game analytics and possession analysis."""
    
    @staticmethod
    def get_post_game_report(game_id, team_id):
        """
        Generate comprehensive post-game report with offensive and defensive analytics.
        Returns data structured exactly like the UI requirements.
        """
        try:
            game = Game.objects.get(id=game_id)
            team_possessions = Possession.objects.filter(
                game=game, team_id=team_id
            ).prefetch_related('team', 'opponent')
            
            opponent_possessions = Possession.objects.filter(
                game=game, opponent_id=team_id
            ).prefetch_related('team', 'opponent')
            
            return {
                'game_info': {
                    'id': game.id,
                    'home_team': {
                        'id': game.home_team.id,
                        'name': game.home_team.name,
                        'logo_url': game.home_team.logo_url,
                    },
                    'away_team': {
                        'id': game.away_team.id,
                        'name': game.away_team.name,
                        'logo_url': game.away_team.logo_url,
                    },
                    'home_score': game.home_team_score,
                    'away_score': game.away_team_score,
                    'game_date': game.game_date,
                },
                'offence': GameAnalyticsService._calculate_offensive_analytics(team_possessions),
                'defence': GameAnalyticsService._calculate_defensive_analytics(opponent_possessions),
                'summary': GameAnalyticsService._calculate_summary_stats(game, team_possessions, opponent_possessions),
            }
        except Game.DoesNotExist:
            return None
    
    @staticmethod
    def _calculate_offensive_analytics(possessions):
        """Calculate offensive possession analytics."""
        offensive_possessions = possessions.filter(
            offensive_sequence__isnull=False
        ).exclude(offensive_sequence='')
        
        # Transition analytics
        transition_data = {
            'fast_break': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Fast Break'
            ),
            'transition': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Transition'
            ),
            'early_off': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Early Off'
            ),
        }
        
        # Offensive sets analytics
        offensive_sets = {}
        for i in range(10):  # Sets 0-9
            offensive_sets[f'set_{i}'] = GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, f'Set {i}'
            )
        
        # Pick and Roll analytics
        pnr_data = {
            'ball_handler': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Ball Handler'
            ),
            'roll_man': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Roll Man'
            ),
            'third_guy': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, '3rd Guy'
            ),
        }
        
        # VS PnR Coverage analytics
        vs_pnr_coverage = {
            'switch': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Switch'
            ),
            'hedge': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Hedge'
            ),
            'drop': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Drop'
            ),
            'trap': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Trap'
            ),
        }
        
        # Other offensive parts
        other_offensive = {
            'closeout': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Closeout'
            ),
            'cuts': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Cuts'
            ),
            'kick_out': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Kick Out'
            ),
            'extra_pass': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'Extra Pass'
            ),
            'after_off_reb': GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, 'After OffReb'
            ),
        }
        
        return {
            'transition': transition_data,
            'offensive_sets': offensive_sets,
            'pnr': pnr_data,
            'vs_pnr_coverage': vs_pnr_coverage,
            'other_offensive': other_offensive,
        }
    
    @staticmethod
    def _calculate_defensive_analytics(opponent_possessions):
        """Calculate defensive analytics based on opponent possessions."""
        defensive_possessions = opponent_possessions.filter(
            defensive_sequence__isnull=False
        ).exclude(defensive_sequence='')
        
        # Coverage analytics
        coverage_data = {
            'switch': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Switch'
            ),
            'switch_low_post': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Switch Low Post'
            ),
            'switch_isolation': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Switch Isolation'
            ),
            'switch_third_guy': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Switch 3rd Guy'
            ),
            'hedge': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Hedge'
            ),
            'drop_weak': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Drop/Weak'
            ),
            'drop_ball_handler': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Drop Ball Handler'
            ),
            'drop_big_guy': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Drop Big Guy'
            ),
            'drop_third_guy': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Drop 3rd Guy'
            ),
            'isolation': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Isolation'
            ),
            'isolation_high_post': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Isolation High Post'
            ),
            'isolation_low_post': GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, 'Isolation Low Post'
            ),
        }
        
        return {
            'coverage': coverage_data,
        }
    
    @staticmethod
    def _calculate_summary_stats(game, team_possessions, opponent_possessions):
        """Calculate summary statistics for the report."""
        # Tagging up (player offensive rebounds)
        tagging_up = {}
        for i in range(6):  # Players 0-5
            player_rebounds = team_possessions.filter(
                is_offensive_rebound=True,
                # This would need to be connected to actual players
            ).count()
            tagging_up[f'player_{i}'] = {
                'player_no': i,
                'count': player_rebounds,
                'percentage': (player_rebounds / team_possessions.count() * 100) if team_possessions.count() > 0 else 0
            }
        
        # Paint touch analytics
        paint_touches = team_possessions.filter(has_paint_touch=True)
        paint_touch_stats = {
            'count': paint_touches.count(),
            'points': paint_touches.aggregate(total=Sum('points_scored'))['total'] or 0,
            'possessions': paint_touches.count(),
            'percentage': (paint_touches.count() / team_possessions.count() * 100) if team_possessions.count() > 0 else 0
        }
        
        # Best offensive 5 (placeholder - would need player data)
        best_offensive_5 = {
            'players': [{'id': i, 'name': f'Player {i}', 'stats': 0} for i in range(5)]
        }
        
        # Best defensive 5 (placeholder - would need player data)
        best_defensive_5 = {
            'players': [{'id': i, 'name': f'Player {i}', 'stats': 0} for i in range(5)]
        }
        
        # Quarters breakdown
        quarters_data = {}
        for quarter in [1, 2, 3, 4]:
            quarter_team_possessions = team_possessions.filter(quarter=quarter)
            quarter_opponent_possessions = opponent_possessions.filter(quarter=quarter)
            
            off_ppp = GameAnalyticsService._calculate_ppp(quarter_team_possessions)
            def_ppp = GameAnalyticsService._calculate_ppp(quarter_opponent_possessions)
            
            quarters_data[f'quarter_{quarter}'] = {
                'quarter': f'{quarter}{"ST" if quarter == 1 else "ND" if quarter == 2 else "RD" if quarter == 3 else "TH"}',
                'off_ppp': off_ppp,
                'def_ppp': def_ppp,
            }
        
        # Add OT if exists
        ot_possessions = team_possessions.filter(quarter__gt=4)
        if ot_possessions.exists():
            ot_opponent_possessions = opponent_possessions.filter(quarter__gt=4)
            quarters_data['overtime'] = {
                'quarter': 'OT',
                'off_ppp': GameAnalyticsService._calculate_ppp(ot_possessions),
                'def_ppp': GameAnalyticsService._calculate_ppp(ot_opponent_possessions),
            }
        
        return {
            'tagging_up': tagging_up,
            'paint_touch': paint_touch_stats,
            'best_offensive_5': best_offensive_5,
            'best_defensive_5': best_defensive_5,
            'quarters': quarters_data,
        }
    
    @staticmethod
    def _calculate_play_type_stats(possessions, play_type):
        """Calculate statistics for a specific play type."""
        filtered_possessions = possessions.filter(
            Q(offensive_sequence__icontains=play_type) | 
            Q(defensive_sequence__icontains=play_type)
        )
        
        if not filtered_possessions.exists():
            return {
                'possessions': 0,
                'ppp': 0.0,
                'adjusted_sq': 0.0,
            }
        
        total_possessions = filtered_possessions.count()
        total_points = filtered_possessions.aggregate(
            total=Sum('points_scored')
        )['total'] or 0
        
        ppp = total_points / total_possessions if total_possessions > 0 else 0
        
        # Adjusted Shot Quality (simplified calculation)
        avg_shoot_quality = filtered_possessions.aggregate(
            avg=Avg('shoot_quality')
        )['avg'] or 0
        
        return {
            'possessions': total_possessions,
            'ppp': round(ppp, 2),
            'adjusted_sq': round(avg_shoot_quality, 2),
        }
    
    @staticmethod
    def _calculate_ppp(possessions):
        """Calculate Points Per Possession."""
        if not possessions.exists():
            return 0.0
        
        total_points = possessions.aggregate(
            total=Sum('points_scored')
        )['total'] or 0
        
        return round(total_points / possessions.count(), 2)
