// lib/features/possessions/presentation/screens/live_tracking_screen.dart

// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/plays/data/models/play_definition_model.dart';
import 'package:flutter_app/features/plays/data/repositories/play_repository.dart';
import 'package:flutter_app/main.dart';
import '../../data/repositories/possession_repository.dart';

// Enums must match the ActionType choices in your Django model
enum ActionType {
  normal,
  startsPossession,
  endsPossession,
  triggersShotResult,
  isShotResult,
  opensTurnoverMenu,
  opensFtMenu,
}

enum PossessionLoggingPhase {
  inactive,
  awaitingTeam,
  active,
  awaitingShotResult,
}

ActionType _getActionType(PlayDefinition play) {
  switch (play.actionTypeString) {
    case 'STARTS_POSSESSION':
      return ActionType.startsPossession;
    case 'ENDS_POSSESSION':
      return ActionType.endsPossession;
    case 'TRIGGERS_SHOT_RESULT':
      return ActionType.triggersShotResult;
    case 'IS_SHOT_RESULT':
      return ActionType.isShotResult;
    case 'OPENS_TURNOVER_MENU':
      return ActionType.opensTurnoverMenu;
    case 'OPENS_FT_MENU':
      return ActionType.opensFtMenu;
    default:
      return ActionType.normal;
  }
}

class LiveTrackingScreen extends StatefulWidget {
  final int gameId;
  const LiveTrackingScreen({super.key, required this.gameId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // --- STATE VARIABLES ---
  Game? _game;
  List<PlayDefinition> _allPlays = [];
  bool _isLoading = true;
  String? _error;

  String _currentPeriod = "Q1";
  List<PlayDefinition> _sequence = [];
  PossessionLoggingPhase _phase = PossessionLoggingPhase.inactive;
  String? _shotType;
  bool? _isHomeTeamPossession;
  double _durationInSeconds = 12.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Future<void> _fetchInitialData() async {
  //   final token = context.read<AuthCubit>().state.token;
  //   if (token == null) {
  //     setState(() {
  //       _isLoading = false;
  //       _error = "Authentication error.";
  //     });
  //     return;
  //   }
  //   try {
  //     final results = await Future.wait([
  //       sl<GameRepository>().getGameDetails(
  //         token: token,
  //         gameId: widget.gameId,
  //       ),
  //       sl<PlayRepository>().getPlaysForTeam(
  //         token: token,
  //         teamId: 1,
  //       ), // Generic plays
  //     ]);
  //     if (mounted) {
  //       setState(() {
  //         _game = results[0] as Game;
  //         _allPlays = results[1] as List<PlayDefinition>;
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //         _error = e.toString();
  //       });
  //     }
  //   }
  // }
  Future<void> _fetchInitialData() async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      /* handle error */
      return;
    }

    try {
      // Fetch both game details and the generic play templates in parallel
      final results = await Future.wait([
        sl<GameRepository>().getGameDetails(
          token: token,
          gameId: widget.gameId,
        ),
        sl<PlayRepository>().getPlayTemplates(token), // <-- USE THE NEW METHOD
      ]);
      if (mounted) {
        setState(() {
          _game = results[0] as Game;
          _allPlays = results[1] as List<PlayDefinition>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onButtonPressed(PlayDefinition play) {
    final actionType = _getActionType(play);
    if (actionType == ActionType.opensTurnoverMenu) {
      if (_phase == PossessionLoggingPhase.active) _showTurnoverMenu();
      return;
    }
    if (actionType == ActionType.opensFtMenu) {
      if (_phase == PossessionLoggingPhase.active) _showFreeThrowMenu();
      return;
    }
    if (play.name == 'Substitution') {
      if (_phase != PossessionLoggingPhase.inactive) _showSubstitutionDialog();
      return;
    }

    setState(() {
      switch (actionType) {
        case ActionType.startsPossession:
          if (_phase == PossessionLoggingPhase.inactive) {
            _phase = PossessionLoggingPhase.awaitingTeam;
            _sequence = [
              PlayDefinition(
                id: 0,
                name: _currentPeriod,
                playType: '',
                teamId: 0,
                actionTypeString: 'NORMAL',
              ),
            ];
            _shotType = null;
            _isHomeTeamPossession = null;
          }
          break;
        case ActionType.endsPossession:
          if (_phase != PossessionLoggingPhase.inactive) {
            _sequence.add(play);
            _showSaveConfirmationDialog();
          }
          break;
        case ActionType.triggersShotResult:
          if (_phase == PossessionLoggingPhase.active) {
            _phase = PossessionLoggingPhase.awaitingShotResult;
            _shotType = play.name;
            _sequence.add(play);
          }
          break;
        case ActionType.isShotResult:
          if (_phase == PossessionLoggingPhase.awaitingShotResult) {
            final outcomeName = '${play.name} ${_shotType ?? ""}';
            _sequence.add(play);
            final finalOutcome = _allPlays.firstWhere(
              (p) => p.name == outcomeName,
              orElse: () => play,
            );
            _sequence.add(finalOutcome);
            _phase = PossessionLoggingPhase.active;
          }
          break;
        default:
          if (play.name == 'Off') {
            if (_phase == PossessionLoggingPhase.awaitingTeam) {
              _isHomeTeamPossession = true;
              _phase = PossessionLoggingPhase.active;
            }
          } else if (play.name == 'Def') {
            if (_phase == PossessionLoggingPhase.awaitingTeam) {
              _isHomeTeamPossession = false;
              _phase = PossessionLoggingPhase.active;
            }
          } else if (play.name == 'UNDO') {
            if (_sequence.length > 1) {
              final removed = _sequence.removeLast();
              if (_getActionType(removed) == ActionType.triggersShotResult) {
                _phase = PossessionLoggingPhase.active;
                _shotType = null;
              }
            }
          } else if (_phase == PossessionLoggingPhase.active) {
            _sequence.add(play);
          }
      }
    });
  }

  void _showSaveConfirmationDialog() {
    if (_isHomeTeamPossession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select 'Off' or 'Def' to assign possession."),
        ),
      );
      return;
    }
    final finalOutcome = _sequence.lastWhere(
      (p) => p.actionTypeString != 'NORMAL' && p.actionTypeString.isNotEmpty,
      orElse: () => _sequence.firstWhere(
        (p) => p.category?.name == 'Outcome',
        orElse: () => PlayDefinition(
          id: 0,
          name: 'OTHER',
          playType: '',
          teamId: 0,
          actionTypeString: 'NORMAL',
        ),
      ),
    );
    final teamWithBall = _isHomeTeamPossession!
        ? _game!.homeTeam
        : _game!.awayTeam;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Save Possession for ${teamWithBall.name}?'),
        content: Text(_sequence.map((p) => p.name).join(' / ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _savePossessionToDatabase(finalOutcome);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePossessionToDatabase(PlayDefinition outcomePlay) async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null || _isHomeTeamPossession == null) return;

    final teamWithBall = _isHomeTeamPossession!
        ? _game!.homeTeam
        : _game!.awayTeam;
    final opponentTeam = _isHomeTeamPossession!
        ? _game!.awayTeam
        : _game!.homeTeam;
    final sequenceString = _sequence.map((p) => p.name).join(' -> ');

    try {
      await sl<PossessionRepository>().createPossession(
        token: token,
        gameId: _game!.id,
        teamId: teamWithBall.id,
        opponentId: opponentTeam.id,
        startTime: "00:00",
        duration: _durationInSeconds.round(),
        quarter: int.tryParse(_currentPeriod.replaceAll('Q', '')) ?? 1,
        outcome: outcomePlay.name.replaceAll(' ', '_').toUpperCase(),
        offensiveSequence: _isHomeTeamPossession! ? sequenceString : '',
        defensiveSequence: !_isHomeTeamPossession! ? sequenceString : '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Possession Saved!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _sequence = [];
          _phase = PossessionLoggingPhase.inactive;
        });
        sl<RefreshSignal>().notify();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    }
  }

  void _showTurnoverMenu() {
    final turnoverPlays = _allPlays
        .where(
          (p) => p.category?.name == 'Outcome' && p.subcategory == 'Turnover',
        )
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(
            title: Text(
              'Select Turnover Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...turnoverPlays.map(
            (play) => ListTile(
              title: Text(play.name),
              onTap: () {
                _onButtonPressed(play);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFreeThrowMenu() {
    final ftPlays = _allPlays
        .where(
          (p) => p.category?.name == 'Outcome' && p.subcategory == 'Free Throw',
        )
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ftPlays
            .map(
              (play) => ListTile(
                leading: Icon(
                  play.name.contains('Made')
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: play.name.contains('Made') ? Colors.green : Colors.red,
                ),
                title: Text(play.name),
                onTap: () {
                  _onButtonPressed(play);
                  Navigator.of(ctx).pop();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showSubstitutionDialog() {
    final playerInController = TextEditingController();
    final playerOutController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Substitution'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: playerInController,
                decoration: const InputDecoration(labelText: 'Player In'),
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: playerOutController,
                decoration: const InputDecoration(labelText: 'Player Out'),
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final subAction =
                    'Sub: #${playerInController.text} IN <-> #${playerOutController.text} OUT';
                _onButtonPressed(
                  PlayDefinition(
                    id: 0,
                    name: subAction,
                    playType: '',
                    teamId: 0,
                    actionTypeString: 'NORMAL',
                  ),
                );
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _game != null
        ? '${_game!.homeTeam.name} vs ${_game!.awayTeam.name}'
        : 'Loading...';
    return Scaffold(
      appBar: UserProfileAppBar(
        title: appBarTitle,
        actions: [
          if (_game != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                onSelected: (newPeriod) =>
                    setState(() => _currentPeriod = newPeriod),
                child: Chip(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  label: Text(
                    _currentPeriod,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'Q1', child: Text('1st Quarter')),
                  PopupMenuItem(value: 'Q2', child: Text('2nd Quarter')),
                  PopupMenuItem(value: 'Q3', child: Text('3rd Quarter')),
                  PopupMenuItem(value: 'Q4', child: Text('4th Quarter')),
                  PopupMenuItem(value: 'OT', child: Text('Overtime')),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _game == null
          ? const Center(child: CircularProgressIndicator())
          : _buildTrackingInterface(_game!),
    );
  }

  Widget _buildSequenceDisplay() {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        _sequence.isEmpty
            ? "Press START to begin."
            : _sequence.map((p) => p.name).join(' / '),
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTrackingInterface(Game game) {
    return Column(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1400,
              height: 780,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TOP ROW (Fixed Flex) ---
                    Expanded(
                      flex: 2, // e.g., takes 2 units of vertical space
                      child: _Panel(
                        title: 'OFFENSE',
                        child: _GenericPanel(
                          category: 'Offense',
                          allPlays: _allPlays,
                          phase: _phase,
                          onButtonPressed: _onButtonPressed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- MIDDLE ROW (Expanded to fill) ---
                    Expanded(
                      flex: 5, // Takes 5 units, will be the largest
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'OFFENSE HALF COURT',
                              child: _OffenseHalfCourtPanel(
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'DEFENSE',
                              child: _GenericPanel(
                                category: 'Defense',
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'PLAYERS',
                              child: _PlayersPanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                                game: game,
                                onShowSubDialog: _showSubstitutionDialog,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- BOTTOM ROW (Fixed Flex) ---
                    Expanded(
                      flex: 3, // Takes 3 units
                      // REMOVED IntrinsicHeight
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _Panel(
                              title: 'CONTROL',
                              child: _GenericPanel(
                                category: 'Control',
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'OUTCOME',
                              child: _GenericPanel(
                                category: 'Outcome',
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'SHOOT',
                              child: _ShootPanel(
                                phase: _phase,
                                duration: _durationInSeconds,
                                onDurationChanged: (val) =>
                                    setState(() => _durationInSeconds = val),
                                allPlays: _allPlays,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'TAG OFFENSIVE REBOUND',
                              child: _GenericPanel(
                                category: 'Tag Offensive Rebound',
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'ADVANCED',
                              child: _GenericPanel(
                                category: 'Advanced',
                                allPlays: _allPlays,
                                phase: _phase,
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildSequenceDisplay(),
      ],
    );
  }
}

// --- PANEL & BUTTON HELPERS ---
class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4.0),
            color: Colors.black87,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(4.0), child: child),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PlayDefinition play;
  final PossessionLoggingPhase phase;
  final ValueChanged<PlayDefinition> onPressed;
  final Color? color;
  final Color? textColor;

  const _ActionButton({
    super.key,
    required this.play,
    required this.phase,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  bool _getIsEnabled() {
    final actionType = _getActionType(play);

    if (actionType == ActionType.startsPossession) {
      return phase == PossessionLoggingPhase.inactive;
    }
    if (actionType == ActionType.isShotResult) {
      return phase == PossessionLoggingPhase.awaitingShotResult;
    }
    if (play.name == 'Off' || play.name == 'Def') {
      return phase == PossessionLoggingPhase.awaitingTeam;
    }
    if (play.name == 'END' || play.name == 'UNDO') {
      return phase != PossessionLoggingPhase.inactive;
    }
    return phase == PossessionLoggingPhase.active;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _getIsEnabled();
    Color buttonColor = color ?? Colors.grey[200]!;
    if (color == null) {
      if (play.name == 'START') buttonColor = Colors.green;
      if (play.name == 'END') buttonColor = Colors.red;
      if (play.name == 'Made') buttonColor = Colors.green;
      if (play.name == 'Miss') buttonColor = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: ElevatedButton(
        onPressed: isEnabled ? () => onPressed(play) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor ?? Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(play.name),
          ),
        ),
      ),
    );
  }
}

// --- DATA-DRIVEN & CUSTOM PANEL WIDGETS ---
class _GenericPanel extends StatelessWidget {
  final String category;
  final List<PlayDefinition> allPlays;
  final PossessionLoggingPhase phase;
  final ValueChanged<PlayDefinition> onButtonPressed;
  const _GenericPanel({
    required this.category,
    required this.allPlays,
    required this.phase,
    required this.onButtonPressed,
  });
  @override
  Widget build(BuildContext context) {
    final categoryPlays = allPlays
        .where((p) => p.category?.name == category)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final Map<String, List<PlayDefinition>> subcategorized = {};
    for (var play in categoryPlays) {
      final sub = play.subcategory ?? 'default';
      if (subcategorized[sub] == null) subcategorized[sub] = [];
      subcategorized[sub]!.add(play);
    }
    // Ensure stable order within each subcategory by ID
    for (final key in subcategorized.keys) {
      subcategorized[key]!.sort((a, b) => a.id.compareTo(b.id));
    }
    return Column(
      children: subcategorized.entries.map((entry) {
        return Row(
          children: entry.value
              .map(
                (play) => Expanded(
                  child: _ActionButton(
                    play: play,
                    phase: phase,
                    onPressed: onButtonPressed,
                  ),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }
}

class _OffenseHalfCourtPanel extends StatelessWidget {
  final List<PlayDefinition> allPlays;
  final PossessionLoggingPhase phase;
  final ValueChanged<PlayDefinition> onButtonPressed;
  const _OffenseHalfCourtPanel({
    required this.allPlays,
    required this.phase,
    required this.onButtonPressed,
  });
  @override
  Widget build(BuildContext context) {
    // Expect server to provide plays with category 'Offense Half Court'
    final source = allPlays
        .where((p) => p.category?.name == 'Offense Half Court')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // Sort by id then split into two halves: left (first half), right (second half)
    final List<PlayDefinition> ordered = List.of(source);
    final mid = (ordered.length / 2).ceil();
    final leftList = ordered.take(mid).toList();
    final rightList = ordered.skip(mid).toList();

    // Build rows: align left[i] with right[i]
    List<Widget> rows = [];
    final maxRows = leftList.length;
    for (int i = 0; i < maxRows; i++) {
      final left = leftList[i];
      final PlayDefinition? right = (i < rightList.length) ? rightList[i] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                play: left,
                phase: phase,
                onPressed: onButtonPressed,
              ),
            ),
            Expanded(
              child: right != null
                  ? _ActionButton(
                      play: right,
                      phase: phase,
                      onPressed: onButtonPressed,                      
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSub(List<PlayDefinition> plays) {
    // No longer used in the two-column chunked layout, keep for compatibility
    if (plays.isEmpty) return const SizedBox.shrink();
    return Row(
      children: plays
          .map(
            (p) => Expanded(
              child: _ActionButton(
                play: p,
                phase: phase,
                onPressed: onButtonPressed,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PlayersPanel extends StatefulWidget {
  final ValueChanged<PlayDefinition> onButtonPressed;
  final PossessionLoggingPhase phase;
  final Game game;
  final VoidCallback onShowSubDialog;
  const _PlayersPanel({
    required this.onButtonPressed,
    required this.phase,
    required this.game,
    required this.onShowSubDialog,
  });

  @override
  State<_PlayersPanel> createState() => _PlayersPanelState();
}

class _PlayersPanelState extends State<_PlayersPanel> {
  late List<User> homePlayers;
  late List<User> awayPlayers;

  @override
  void initState() {
    super.initState();
    homePlayers = widget.game.homeTeam.players;
    awayPlayers = widget.game.awayTeam.players;
  }

  @override
  void didUpdateWidget(covariant _PlayersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game != oldWidget.game) {
      setState(() {
        homePlayers = widget.game.homeTeam.players;
        awayPlayers = widget.game.awayTeam.players;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActionEnabled = widget.phase == PossessionLoggingPhase.active;

    // Use a LayoutBuilder to get the available height for the grids
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate a good height for the player grids, leaving space for the header and action buttons
        final gridHeight = (constraints.maxHeight - 60) / 2;

        return Column(
          children: [
            const Text(
              "Home / Away",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),

            // --- PLAYER GRIDS ---
            SizedBox(
              height: gridHeight * 2, // Give the Row a fixed height
              child: Row(
                children: [
                  Expanded(child: _buildPlayerGrid(homePlayers, true)),
                  Expanded(child: _buildPlayerGrid(awayPlayers, false)),
                ],
              ),
            ),

            // --- ACTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    play: PlayDefinition.empty('BoxOut -1'),
                    phase: widget.phase,
                    onPressed: widget.onButtonPressed,
                    color: Colors.purple,
                    textColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    play: PlayDefinition.empty('DefReb +1'),
                    phase: widget.phase,
                    onPressed: widget.onButtonPressed,
                    color: Colors.purple,
                    textColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    play: PlayDefinition.empty('OffReb -1'),
                    phase: widget.phase,
                    onPressed: widget.onButtonPressed,
                    color: Colors.purple,
                    textColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: ElevatedButton(
                      onPressed: isActionEnabled
                          ? widget.onShowSubDialog
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sub', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    play: PlayDefinition.empty('Recover -1'),
                    phase: widget.phase,
                    onPressed: widget.onButtonPressed,
                    color: Colors.purple,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Helper to build a single player grid
  Widget _buildPlayerGrid(List<User> players, bool isHome) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.4, // Wider buttons for readability
      ),
      itemCount: 10, // Always build 10 slots
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final player = index < players.length ? players[index] : null;
        final playDef = PlayDefinition.empty(
          player?.jerseyNumber?.toString() ?? '#',
        );
        return _ActionButton(
          play: playDef,
          phase: widget.phase,
          onPressed: (p) {
            if (player != null) {
              final teamPrefix = isHome ? 'H' : 'A';
              widget.onButtonPressed(
                PlayDefinition.empty('$teamPrefix#${player.jerseyNumber}'),
              );
            }
            // Optional: Show a dialog to enter a number if player is null
          },
          color: isHome ? Colors.blue[800] : Colors.grey[800],
          textColor: Colors.white,
        );
      },
    );
  }
}

class _ShootPanel extends StatelessWidget {
  final PossessionLoggingPhase phase;
  final double duration;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<PlayDefinition> onButtonPressed;
  final List<PlayDefinition> allPlays;
  const _ShootPanel({
    required this.phase,
    required this.duration,
    required this.onDurationChanged,
    required this.allPlays,
    required this.onButtonPressed,
  });
  @override
  Widget build(BuildContext context) {
    final qualityPlays = allPlays
        .where(
          (p) => p.category?.name == 'Shoot' && p.subcategory == 'ShotQuality',
        )
        .toList();
    return Column(
      children: [
        const Text(
          "Shot Quality",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Row(
            children: qualityPlays
                .map(
                  (p) => Expanded(
                    child: _ActionButton(
                      play: p,
                      phase: phase,
                      onPressed: onButtonPressed,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Duration",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          "${duration.round()}s",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: duration,
          min: 1,
          max: 24,
          divisions: 23,
          label: '${duration.round()}s',
          onChanged: phase == PossessionLoggingPhase.active
              ? onDurationChanged
              : null,
        ),
      ],
    );
  }
}
