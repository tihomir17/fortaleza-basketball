import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:intl/intl.dart';

class AdvancedPostGameReportScreen extends StatefulWidget {
  final int gameId;

  const AdvancedPostGameReportScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<AdvancedPostGameReportScreen> createState() => _AdvancedPostGameReportScreenState();
}

class _AdvancedPostGameReportScreenState extends State<AdvancedPostGameReportScreen> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdvancedReport();
  }

  Future<void> _loadAdvancedReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      // For now, we'll use mock data that matches the structure from the images
      // In a real implementation, this would come from the backend API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      final mockData = _generateMockAdvancedReportData();
      
      setState(() {
        _reportData = mockData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load advanced report: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _generateMockAdvancedReportData() {
    return {
      'game_info': {
        'home_team': 'Fortaleza B.C.',
        'away_team': 'Opponent Team',
        'game_date': DateTime.now(),
        'home_score': 108,
        'away_score': 95,
      },
      'offense': {
        'play_types': {
          'pick_n_rolls': {
            'drags': {'game': 12.0, 'rank': 24, 'last5': 15.5, 'last5_rank': 14, 'season': 15.0, 'season_rank': 17, 'xppp': 1.09, 'xppp_rank': 27},
            'mids': {'game': 39.0, 'rank': 2, 'last5': 31.3, 'last5_rank': 11, 'season': 31.1, 'season_rank': 11, 'xppp': 1.03, 'xppp_rank': 30},
            'sides': {'game': 17.0, 'rank': 5, 'last5': 15.5, 'last5_rank': 7, 'season': 17.2, 'season_rank': 4, 'xppp': 0.87, 'xppp_rank': 30},
          },
          'closeouts': {
            'shot_percent': {'game': 46.2, 'rank': 14, 'last5': 51.9, 'last5_rank': 10, 'season': 51.9, 'season_rank': 3, 'xppp': 1.15, 'xppp_rank': 30},
            'drib_percent': {'game': 35.9, 'rank': 3, 'last5': 29.4, 'last5_rank': 18, 'season': 29.7, 'season_rank': 20, 'xppp': 0.97, 'xppp_rank': 30},
            'pump_percent': {'game': 7.7, 'rank': 4, 'last5': 4.3, 'last5_rank': 21, 'season': 5.0, 'season_rank': 20, 'xppp': 1.02, 'xppp_rank': 30},
            'pass_percent': {'game': 7.7, 'rank': 30, 'last5': 13.4, 'last5_rank': 18, 'season': 11.8, 'season_rank': 26, 'xppp': 1.18, 'xppp_rank': 17},
          },
          'handoffs': {
            'dhos': {'game': 15.0, 'rank': 27, 'last5': 20.3, 'last5_rank': 22, 'season': 28.7, 'season_rank': 6, 'xppp': 1.10, 'xppp_rank': 21},
          },
          'isolations': {
            'isos': {'game': 12.0, 'rank': 24, 'last5': 13.5, 'last5_rank': 18, 'season': 11.1, 'season_rank': 26, 'xppp': 1.08, 'xppp_rank': 26},
            'post_ups': {'game': 5.0, 'rank': 20, 'last5': 5.0, 'last5_rank': 23, 'season': 4.7, 'season_rank': 25, 'xppp': 1.20, 'xppp_rank': 2},
          },
          'transition': {
            'stl_percent': {'game': 77.8, 'rank': 4, 'last5': 75.0, 'last5_rank': 15, 'season': 75.0, 'season_rank': 12, 'xppp': 1.23, 'xppp_rank': 29},
            'fgm_percent': {'game': 21.2, 'rank': 3, 'last5': 16.8, 'last5_rank': 5, 'season': 14.8, 'season_rank': 8, 'xppp': 1.03, 'xppp_rank': 11},
            'dreb_percent': {'game': 50.0, 'rank': 2, 'last5': 41.7, 'last5_rank': 13, 'season': 49.1, 'season_rank': 2, 'xppp': 0.89, 'xppp_rank': 30},
          },
        },
        'shot_spectrum': {
          'rim': {'shots': 39.0, 'rank': 5, 'last5': 37.3, 'last5_rank': 3, 'season': 40.5, 'season_rank': 3, 'ppp': 1.44, 'ppp_rank': 23},
          'non_rim_paint': {'shots': 14.0, 'rank': 12, 'last5': 14.0, 'last5_rank': 15, 'season': 17.5, 'season_rank': 3, 'ppp': 1.36, 'ppp_rank': 1},
          'non_paint_2': {'shots': 5.0, 'rank': 1, 'last5': 5.3, 'last5_rank': 2, 'season': 8.8, 'season_rank': 10, 'ppp': 1.60, 'ppp_rank': 1},
          'three_point': {
            'corner_3': {'shots': 7.0, 'rank': 30, 'last5': 12.3, 'last5_rank': 6, 'season': 10.5, 'season_rank': 14, 'ppp': 2.14, 'ppp_rank': 1},
            'above_break_3': {'shots': 26.0, 'rank': 19, 'last5': 23.5, 'last5_rank': 28, 'season': 21.6, 'season_rank': 30, 'ppp': 1.12, 'ppp_rank': 30},
          },
        },
      },
      'defense': {
        'play_types': {
          'pick_n_rolls': {
            'drags': {'game': 26.0, 'rank': 1, 'last5': 17.3, 'last5_rank': 11, 'season': 15.0, 'season_rank': 17, 'xppp': 1.25, 'xppp_rank': 1},
            'mids': {'game': 25.0, 'rank': 27, 'last5': 31.8, 'last5_rank': 10, 'season': 30.4, 'season_rank': 9, 'xppp': 1.18, 'xppp_rank': 30},
            'sides': {'game': 16.0, 'rank': 6, 'last5': 11.8, 'last5_rank': 24, 'season': 14.8, 'season_rank': 13, 'xppp': 1.09, 'xppp_rank': 8},
          },
          'closeouts': {
            'shot_percent': {'game': 40.9, 'rank': 1, 'last5': 51.1, 'last5_rank': 22, 'season': 45.9, 'season_rank': 14, 'xppp': 1.27, 'xppp_rank': 1},
            'drib_percent': {'game': 31.8, 'rank': 24, 'last5': 26.1, 'last5_rank': 7, 'season': 31.3, 'season_rank': 18, 'xppp': 0.77, 'xppp_rank': 1},
            'pump_percent': {'game': 4.5, 'rank': 5, 'last5': 5.7, 'last5_rank': 20, 'season': 5.9, 'season_rank': 21, 'xppp': 1.51, 'xppp_rank': 30},
            'pass_percent': {'game': 20.5, 'rank': 30, 'last5': 15.3, 'last5_rank': 15, 'season': 14.9, 'season_rank': 8, 'xppp': 1.19, 'xppp_rank': 17},
          },
          'handoffs': {
            'dhos': {'game': 20.0, 'rank': 28, 'last5': 26.8, 'last5_rank': 10, 'season': 25.8, 'season_rank': 6, 'xppp': 1.10, 'xppp_rank': 12},
          },
          'isolations': {
            'isos': {'game': 23.0, 'rank': 1, 'last5': 18.8, 'last5_rank': 5, 'season': 15.4, 'season_rank': 9, 'xppp': 1.15, 'xppp_rank': 4},
            'post_ups': {'game': 5.0, 'rank': 3, 'last5': 4.8, 'last5_rank': 8, 'season': 8.1, 'season_rank': 27, 'xppp': 1.33, 'xppp_rank': 30},
          },
          'transition': {
            'stl_percent': {'game': 75.0, 'rank': 23, 'last5': 68.3, 'last5_rank': 10, 'season': 68.9, 'season_rank': 6, 'xppp': 1.50, 'xppp_rank': 30},
            'fgm_percent': {'game': 15.4, 'rank': 27, 'last5': 11.4, 'last5_rank': 14, 'season': 12.1, 'season_rank': 12, 'xppp': 0.78, 'xppp_rank': 1},
            'dreb_percent': {'game': 54.2, 'rank': 30, 'last5': 38.2, 'last5_rank': 11, 'season': 42.8, 'season_rank': 16, 'xppp': 1.07, 'xppp_rank': 4},
          },
        },
        'shot_spectrum': {
          'rim': {'shots': 38.0, 'rank': 30, 'last5': 32.0, 'last5_rank': 15, 'season': 35.7, 'season_rank': 26, 'ppp': 1.26, 'ppp_rank': 1},
          'non_rim_paint': {'shots': 8.0, 'rank': 1, 'last5': 14.0, 'last5_rank': 17, 'season': 13.3, 'season_rank': 9, 'ppp': 1.25, 'ppp_rank': 28},
          'non_paint_2': {'shots': 15.0, 'rank': 1, 'last5': 10.5, 'last5_rank': 13, 'season': 10.8, 'season_rank': 14, 'ppp': 0.93, 'ppp_rank': 3},
          'three_point': {
            'corner_3': {'shots': 8.0, 'rank': 1, 'last5': 12.5, 'last5_rank': 27, 'season': 11.4, 'season_rank': 24, 'ppp': 1.88, 'ppp_rank': 30},
            'above_break_3': {'shots': 22.0, 'rank': 1, 'last5': 27.8, 'last5_rank': 15, 'season': 26.8, 'season_rank': 11, 'ppp': 1.18, 'ppp_rank': 6},
          },
        },
      },
    };
  }

  Color _getRankColor(int rank) {
    if (rank <= 10) return Colors.green;
    if (rank <= 20) return Colors.orange;
    return Colors.red;
  }

  String _getRankSuffix(int rank) {
    if (rank >= 11 && rank <= 13) return 'th';
    switch (rank % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildRankCell(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRankColor(rank),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$rank${_getRankSuffix(rank)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDataTable({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              dataTextStyle: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
              columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
              rows: data.map((row) {
                return DataRow(
                  cells: columns.map((column) {
                    final value = row[column];
                    if (value is int && column.toLowerCase().contains('rank')) {
                      return DataCell(_buildRankCell(value));
                    }
                    return DataCell(Text(value?.toString() ?? '-'));
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTypesSection(String side, Map<String, dynamic> playTypes) {
    final theme = Theme.of(context);
    final capitalizedSide = side[0].toUpperCase() + side.substring(1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$capitalizedSide - PLAY TYPES',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pick'n'Rolls
          _buildDataTable(
            title: 'Pick\'n\'Rolls',
            columns: ['Stat', 'Game', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'xPPP', 'xPPP Rank'],
            data: [
              {
                'Stat': 'Drags',
                'Game': playTypes['pick_n_rolls']['drags']['game'].toString(),
                'Game Rank': playTypes['pick_n_rolls']['drags']['rank'],
                'Last5': playTypes['pick_n_rolls']['drags']['last5'].toString(),
                'Last5 Rank': playTypes['pick_n_rolls']['drags']['last5_rank'],
                'Season': playTypes['pick_n_rolls']['drags']['season'].toString(),
                'Season Rank': playTypes['pick_n_rolls']['drags']['season_rank'],
                'xPPP': playTypes['pick_n_rolls']['drags']['xppp'].toString(),
                'xPPP Rank': playTypes['pick_n_rolls']['drags']['xppp_rank'],
              },
              {
                'Stat': 'Mids',
                'Game': playTypes['pick_n_rolls']['mids']['game'].toString(),
                'Game Rank': playTypes['pick_n_rolls']['mids']['rank'],
                'Last5': playTypes['pick_n_rolls']['mids']['last5'].toString(),
                'Last5 Rank': playTypes['pick_n_rolls']['mids']['last5_rank'],
                'Season': playTypes['pick_n_rolls']['mids']['season'].toString(),
                'Season Rank': playTypes['pick_n_rolls']['mids']['season_rank'],
                'xPPP': playTypes['pick_n_rolls']['mids']['xppp'].toString(),
                'xPPP Rank': playTypes['pick_n_rolls']['mids']['xppp_rank'],
              },
              {
                'Stat': 'Sides',
                'Game': playTypes['pick_n_rolls']['sides']['game'].toString(),
                'Game Rank': playTypes['pick_n_rolls']['sides']['rank'],
                'Last5': playTypes['pick_n_rolls']['sides']['last5'].toString(),
                'Last5 Rank': playTypes['pick_n_rolls']['sides']['last5_rank'],
                'Season': playTypes['pick_n_rolls']['sides']['season'].toString(),
                'Season Rank': playTypes['pick_n_rolls']['sides']['season_rank'],
                'xPPP': playTypes['pick_n_rolls']['sides']['xppp'].toString(),
                'xPPP Rank': playTypes['pick_n_rolls']['sides']['xppp_rank'],
              },
            ],
          ),
          
          // Closeouts
          _buildDataTable(
            title: 'Closeouts',
            columns: ['Stat', 'Game', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'xPPP', 'xPPP Rank'],
            data: [
              {
                'Stat': '% Shot',
                'Game': playTypes['closeouts']['shot_percent']['game'].toString(),
                'Game Rank': playTypes['closeouts']['shot_percent']['rank'],
                'Last5': playTypes['closeouts']['shot_percent']['last5'].toString(),
                'Last5 Rank': playTypes['closeouts']['shot_percent']['last5_rank'],
                'Season': playTypes['closeouts']['shot_percent']['season'].toString(),
                'Season Rank': playTypes['closeouts']['shot_percent']['season_rank'],
                'xPPP': playTypes['closeouts']['shot_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['closeouts']['shot_percent']['xppp_rank'],
              },
              {
                'Stat': '% Drib',
                'Game': playTypes['closeouts']['drib_percent']['game'].toString(),
                'Game Rank': playTypes['closeouts']['drib_percent']['rank'],
                'Last5': playTypes['closeouts']['drib_percent']['last5'].toString(),
                'Last5 Rank': playTypes['closeouts']['drib_percent']['last5_rank'],
                'Season': playTypes['closeouts']['drib_percent']['season'].toString(),
                'Season Rank': playTypes['closeouts']['drib_percent']['season_rank'],
                'xPPP': playTypes['closeouts']['drib_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['closeouts']['drib_percent']['xppp_rank'],
              },
              {
                'Stat': '% Pump',
                'Game': playTypes['closeouts']['pump_percent']['game'].toString(),
                'Game Rank': playTypes['closeouts']['pump_percent']['rank'],
                'Last5': playTypes['closeouts']['pump_percent']['last5'].toString(),
                'Last5 Rank': playTypes['closeouts']['pump_percent']['last5_rank'],
                'Season': playTypes['closeouts']['pump_percent']['season'].toString(),
                'Season Rank': playTypes['closeouts']['pump_percent']['season_rank'],
                'xPPP': playTypes['closeouts']['pump_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['closeouts']['pump_percent']['xppp_rank'],
              },
              {
                'Stat': '% Pass',
                'Game': playTypes['closeouts']['pass_percent']['game'].toString(),
                'Game Rank': playTypes['closeouts']['pass_percent']['rank'],
                'Last5': playTypes['closeouts']['pass_percent']['last5'].toString(),
                'Last5 Rank': playTypes['closeouts']['pass_percent']['last5_rank'],
                'Season': playTypes['closeouts']['pass_percent']['season'].toString(),
                'Season Rank': playTypes['closeouts']['pass_percent']['season_rank'],
                'xPPP': playTypes['closeouts']['pass_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['closeouts']['pass_percent']['xppp_rank'],
              },
            ],
          ),
          
          // Handoffs
          _buildDataTable(
            title: 'HandOffs',
            columns: ['Stat', 'Game', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'xPPP', 'xPPP Rank'],
            data: [
              {
                'Stat': 'DHOs',
                'Game': playTypes['handoffs']['dhos']['game'].toString(),
                'Game Rank': playTypes['handoffs']['dhos']['rank'],
                'Last5': playTypes['handoffs']['dhos']['last5'].toString(),
                'Last5 Rank': playTypes['handoffs']['dhos']['last5_rank'],
                'Season': playTypes['handoffs']['dhos']['season'].toString(),
                'Season Rank': playTypes['handoffs']['dhos']['season_rank'],
                'xPPP': playTypes['handoffs']['dhos']['xppp'].toString(),
                'xPPP Rank': playTypes['handoffs']['dhos']['xppp_rank'],
              },
            ],
          ),
          
          // Isolations
          _buildDataTable(
            title: 'Isolations',
            columns: ['Stat', 'Game', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'xPPP', 'xPPP Rank'],
            data: [
              {
                'Stat': 'ISOs',
                'Game': playTypes['isolations']['isos']['game'].toString(),
                'Game Rank': playTypes['isolations']['isos']['rank'],
                'Last5': playTypes['isolations']['isos']['last5'].toString(),
                'Last5 Rank': playTypes['isolations']['isos']['last5_rank'],
                'Season': playTypes['isolations']['isos']['season'].toString(),
                'Season Rank': playTypes['isolations']['isos']['season_rank'],
                'xPPP': playTypes['isolations']['isos']['xppp'].toString(),
                'xPPP Rank': playTypes['isolations']['isos']['xppp_rank'],
              },
              {
                'Stat': 'PostUps',
                'Game': playTypes['isolations']['post_ups']['game'].toString(),
                'Game Rank': playTypes['isolations']['post_ups']['rank'],
                'Last5': playTypes['isolations']['post_ups']['last5'].toString(),
                'Last5 Rank': playTypes['isolations']['post_ups']['last5_rank'],
                'Season': playTypes['isolations']['post_ups']['season'].toString(),
                'Season Rank': playTypes['isolations']['post_ups']['season_rank'],
                'xPPP': playTypes['isolations']['post_ups']['xppp'].toString(),
                'xPPP Rank': playTypes['isolations']['post_ups']['xppp_rank'],
              },
            ],
          ),
          
          // Transition
          _buildDataTable(
            title: 'Transition',
            columns: ['Stat', 'Game', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'xPPP', 'xPPP Rank'],
            data: [
              {
                'Stat': 'STL%',
                'Game': playTypes['transition']['stl_percent']['game'].toString(),
                'Game Rank': playTypes['transition']['stl_percent']['rank'],
                'Last5': playTypes['transition']['stl_percent']['last5'].toString(),
                'Last5 Rank': playTypes['transition']['stl_percent']['last5_rank'],
                'Season': playTypes['transition']['stl_percent']['season'].toString(),
                'Season Rank': playTypes['transition']['stl_percent']['season_rank'],
                'xPPP': playTypes['transition']['stl_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['transition']['stl_percent']['xppp_rank'],
              },
              {
                'Stat': 'FGM%',
                'Game': playTypes['transition']['fgm_percent']['game'].toString(),
                'Game Rank': playTypes['transition']['fgm_percent']['rank'],
                'Last5': playTypes['transition']['fgm_percent']['last5'].toString(),
                'Last5 Rank': playTypes['transition']['fgm_percent']['last5_rank'],
                'Season': playTypes['transition']['fgm_percent']['season'].toString(),
                'Season Rank': playTypes['transition']['fgm_percent']['season_rank'],
                'xPPP': playTypes['transition']['fgm_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['transition']['fgm_percent']['xppp_rank'],
              },
              {
                'Stat': 'DREB%',
                'Game': playTypes['transition']['dreb_percent']['game'].toString(),
                'Game Rank': playTypes['transition']['dreb_percent']['rank'],
                'Last5': playTypes['transition']['dreb_percent']['last5'].toString(),
                'Last5 Rank': playTypes['transition']['dreb_percent']['last5_rank'],
                'Season': playTypes['transition']['dreb_percent']['season'].toString(),
                'Season Rank': playTypes['transition']['dreb_percent']['season_rank'],
                'xPPP': playTypes['transition']['dreb_percent']['xppp'].toString(),
                'xPPP Rank': playTypes['transition']['dreb_percent']['xppp_rank'],
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShotSpectrumSection(String side, Map<String, dynamic> shotSpectrum) {
    final theme = Theme.of(context);
    final capitalizedSide = side[0].toUpperCase() + side.substring(1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$capitalizedSide - Shot Spectrum',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDataTable(
            title: 'Shot Distribution & Efficiency',
            columns: ['Location', 'Shots', 'Game Rank', 'Last5', 'Last5 Rank', 'Season', 'Season Rank', 'PPP', 'PPP Rank'],
            data: [
              {
                'Location': 'Rim',
                'Shots': shotSpectrum['rim']['shots'].toString(),
                'Game Rank': shotSpectrum['rim']['rank'],
                'Last5': shotSpectrum['rim']['last5'].toString(),
                'Last5 Rank': shotSpectrum['rim']['last5_rank'],
                'Season': shotSpectrum['rim']['season'].toString(),
                'Season Rank': shotSpectrum['rim']['season_rank'],
                'PPP': shotSpectrum['rim']['ppp'].toString(),
                'PPP Rank': shotSpectrum['rim']['ppp_rank'],
              },
              {
                'Location': 'Non-Rim Paint',
                'Shots': shotSpectrum['non_rim_paint']['shots'].toString(),
                'Game Rank': shotSpectrum['non_rim_paint']['rank'],
                'Last5': shotSpectrum['non_rim_paint']['last5'].toString(),
                'Last5 Rank': shotSpectrum['non_rim_paint']['last5_rank'],
                'Season': shotSpectrum['non_rim_paint']['season'].toString(),
                'Season Rank': shotSpectrum['non_rim_paint']['season_rank'],
                'PPP': shotSpectrum['non_rim_paint']['ppp'].toString(),
                'PPP Rank': shotSpectrum['non_rim_paint']['ppp_rank'],
              },
              {
                'Location': 'Non-Paint 2',
                'Shots': shotSpectrum['non_paint_2']['shots'].toString(),
                'Game Rank': shotSpectrum['non_paint_2']['rank'],
                'Last5': shotSpectrum['non_paint_2']['last5'].toString(),
                'Last5 Rank': shotSpectrum['non_paint_2']['last5_rank'],
                'Season': shotSpectrum['non_paint_2']['season'].toString(),
                'Season Rank': shotSpectrum['non_paint_2']['season_rank'],
                'PPP': shotSpectrum['non_paint_2']['ppp'].toString(),
                'PPP Rank': shotSpectrum['non_paint_2']['ppp_rank'],
              },
              {
                'Location': 'C3',
                'Shots': shotSpectrum['three_point']['corner_3']['shots'].toString(),
                'Game Rank': shotSpectrum['three_point']['corner_3']['rank'],
                'Last5': shotSpectrum['three_point']['corner_3']['last5'].toString(),
                'Last5 Rank': shotSpectrum['three_point']['corner_3']['last5_rank'],
                'Season': shotSpectrum['three_point']['corner_3']['season'].toString(),
                'Season Rank': shotSpectrum['three_point']['corner_3']['season_rank'],
                'PPP': shotSpectrum['three_point']['corner_3']['ppp'].toString(),
                'PPP Rank': shotSpectrum['three_point']['corner_3']['ppp_rank'],
              },
              {
                'Location': 'AtB',
                'Shots': shotSpectrum['three_point']['above_break_3']['shots'].toString(),
                'Game Rank': shotSpectrum['three_point']['above_break_3']['rank'],
                'Last5': shotSpectrum['three_point']['above_break_3']['last5'].toString(),
                'Last5 Rank': shotSpectrum['three_point']['above_break_3']['last5_rank'],
                'Season': shotSpectrum['three_point']['above_break_3']['season'].toString(),
                'Season Rank': shotSpectrum['three_point']['above_break_3']['season_rank'],
                'PPP': shotSpectrum['three_point']['above_break_3']['ppp'].toString(),
                'PPP Rank': shotSpectrum['three_point']['above_break_3']['ppp_rank'],
              },
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Advanced Post-Game Report'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Advanced Post-Game Report'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAdvancedReport,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportData == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Advanced Post-Game Report'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No report data available.'),
        ),
      );
    }

    final gameInfo = _reportData!['game_info'] as Map<String, dynamic>;
    final offense = _reportData!['offense'] as Map<String, dynamic>;
    final defense = _reportData!['defense'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Advanced Post-Game Report'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement PDF export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon!')),
              );
            },
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '${gameInfo['home_team']} vs ${gameInfo['away_team']}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${gameInfo['home_score']} - ${gameInfo['away_score']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(gameInfo['game_date']),
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Offense Section
            _buildPlayTypesSection('offense', offense['play_types']),
            _buildShotSpectrumSection('offense', offense['shot_spectrum']),
            
            const SizedBox(height: 32),
            
            // Defense Section
            _buildPlayTypesSection('defense', defense['play_types']),
            _buildShotSpectrumSection('defense', defense['shot_spectrum']),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
