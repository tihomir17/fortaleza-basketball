// lib/features/possessions/presentation/screens/live_tracking_screen.dart

// ignore_for_file: unused_import, unused_element_parameter, unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_state.dart';
import 'package:flutter_app/features/plays/data/models/play_definition_model.dart';
import 'package:flutter_app/features/plays/presentation/cubit/playbook_cubit.dart';
import 'package:flutter_app/features/plays/presentation/cubit/playbook_state.dart';
import 'package:flutter_app/features/possessions/data/repositories/possession_repository.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PossessionLoggingPhase {
  inactive,
  awaitingTeam,
  homeTeamPossesion,
  awayTeamPossesion,
  active,
  awaitingShotResult,
}

class LiveTrackingScreen extends StatefulWidget {
  final int gameId;
  const LiveTrackingScreen({super.key, required this.gameId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // Local UI state for the screen
  String _currentPeriod = "Q1";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GameDetailCubit>()
        ..fetchGameDetails(
          token: context.read<AuthCubit>().state.token!,
          gameId: widget.gameId,
          loadPossessions: false, // Don't need possessions for live tracking
        ),
      child: BlocBuilder<GameDetailCubit, GameDetailState>(
        builder: (context, state) {
          // Determine the AppBar title based on the state
          final game = state.game;
          final String appBarTitle = game != null
              ? '${game.homeTeam.name} vs ${game.awayTeam.name}'
              : 'Loading Session...';

          return Scaffold(
            appBar: UserProfileAppBar(
              title: appBarTitle,
              actions: [
                // Only show the period selector if the game has loaded
                if (state.status == GameDetailStatus.success && game != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PopupMenuButton<String>(
                      onSelected: (newPeriod) {
                        // setState is available here because we are in a StatefulWidget
                        setState(() {
                          _currentPeriod = newPeriod;
                        });
                      },
                      child: Chip(
                        backgroundColor: Colors.red,
                        label: Text(
                          _currentPeriod,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'Q1',
                          child: Text('1st Quarter'),
                        ),
                        const PopupMenuItem(
                          value: 'Q2',
                          child: Text('2nd Quarter'),
                        ),
                        const PopupMenuItem(
                          value: 'Q3',
                          child: Text('3rd Quarter'),
                        ),
                        const PopupMenuItem(
                          value: 'Q4',
                          child: Text('4th Quarter'),
                        ),
                        const PopupMenuItem(
                          value: 'OT',
                          child: Text('Overtime'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: _buildBody(state), // Pass the state to the body builder
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(GameDetailState state) {
    if (state.status == GameDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GameDetailStatus.failure || state.game == null) {
      return Center(
        child: Text(state.errorMessage ?? "Could not load game data."),
      );
    }
    // If data is loaded, build the main view
    return _LiveTrackingView(game: state.game!, currentPeriod: _currentPeriod);
  }
}

// The main UI view, which is now stateless as its state is passed in
class _LiveTrackingView extends StatelessWidget {
  final Game game;
  final String currentPeriod;

  const _LiveTrackingView({required this.game, required this.currentPeriod});

  // This StatefulWidget holds the local state for the sequence
  @override
  Widget build(BuildContext context) {
    return _LiveTrackingStatefulWrapper(
      game: game,
      currentPeriod: currentPeriod,
    );
  }
}

class _LiveTrackingStatefulWrapper extends StatefulWidget {
  final Game game;
  final String currentPeriod;

  const _LiveTrackingStatefulWrapper({
    required this.game,
    required this.currentPeriod,
  });

  @override
  __LiveTrackingStatefulWrapperState createState() =>
      __LiveTrackingStatefulWrapperState();
}

class __LiveTrackingStatefulWrapperState
    extends State<_LiveTrackingStatefulWrapper> {
  List<String> _sequence = [];

  PossessionLoggingPhase _phase = PossessionLoggingPhase.inactive;

  double _durationInSeconds = 12.0;

  String? _finalOutcome; // To hold outcomes like 'MADE_2PT', 'TO_TRAVEL', etc.
  String? _shotType; // To track if '2pts' or '3pts' was pressed
  bool? _isHomeTeamPossession; // To determine which team had the ball

  void _onButtonPressed(String action) {
    if (action.startsWith('TO_') ||
        action.startsWith('MADE_') ||
        action.startsWith('MISSED_')) {
      setState(() => _finalOutcome = action);
      // We still add it to the sequence for the user to see
    }
    // --- SPECIAL BUTTON LOGIC ---
    if (action == 'Turnover') {
      _showTurnoverMenu();
      return;
    }
    if (action == 'Free Throw') {
      _showFreeThrowMenu();
      return;
    }

    if (action == 'Substitution') {
      _showSubstitutionDialog(context);
    }
    setState(() {
      if (action == 'START') {
        _phase = PossessionLoggingPhase.awaitingTeam;
        _sequence = [widget.currentPeriod];
        _finalOutcome = null;
        _shotType = null;
        _isHomeTeamPossession = null;
        return;
      }

      if (action == 'Off' || action == 'Def') {
        _isHomeTeamPossession = (action == 'Off');
        _phase = PossessionLoggingPhase.active; // All buttons now become active
        return; // Don't add to sequence
      }

      // If we are awaiting a shot result, only allow Made or Miss
      if (_phase == PossessionLoggingPhase.awaitingShotResult) {
        if (action == 'Made' || action == 'Missed') {
          _finalOutcome =
              '${action.toUpperCase()}_$_shotType'; // e.g., MADE_2PT
          _sequence.add(action);
          _phase =
              PossessionLoggingPhase.active; // Return to normal active state
        }
        return; // Ignore all other buttons
      }

      // If the session is totally inactive, ignore all other buttons
      if (_phase == PossessionLoggingPhase.inactive) return;

      // For 2pt/3pt, enter the special "awaiting shot result" phase
      if (action == '2pts' || action == '3pts') {
        _phase = PossessionLoggingPhase.awaitingShotResult;
        _shotType = action.toUpperCase();
        _sequence.add(action);
        return;
      }

      if (action == 'END') {
        showSaveConfirmationDialog();
        _phase = PossessionLoggingPhase.inactive;
        _sequence.add(action);
        return;
      }

      // Standard UNDO logic (simplified for now)
      if (action == "UNDO") {
        if (_sequence.length > 1) _sequence.removeLast();
        _phase =
            PossessionLoggingPhase.active; // Always return to active after undo
        return;
      }

      _sequence.add(action);
    });
  }

  Future<void> savePossessionToDatabase(
    Team team,
    Team opponent,
    String sequence,
  ) async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null) return;

    try {
      await sl<PossessionRepository>().createPossession(
        token: token,
        gameId: widget.game.id,
        teamId: team.id,
        opponentId: opponent.id,
        startTime: "00:00", // Placeholder
        duration: 10, // Placeholder
        quarter: int.tryParse(widget.currentPeriod.replaceAll('Q', '')) ?? 1,
        outcome: _finalOutcome!,
        offensiveSequence: _isHomeTeamPossession! ? sequence : '',
        defensiveSequence: !_isHomeTeamPossession! ? sequence : '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Possession Saved!"),
            backgroundColor: Colors.green,
          ),
        );
        // Clear the sequence for the next one
        setState(() => _sequence = []);
        // Notify other screens to refresh
        sl<RefreshSignal>().notify();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- SAVE POSSESSION LOGIC ---
  void showSaveConfirmationDialog() {
    final game = context.read<GameDetailCubit>().state.game;
    if (game == null) return;

    // Determine which team had the ball and which was the opponent
    if (_isHomeTeamPossession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select 'Off' or 'Def' to assign possession."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final teamWithBall = _isHomeTeamPossession! ? game.homeTeam : game.awayTeam;
    final opponentTeam = _isHomeTeamPossession! ? game.awayTeam : game.homeTeam;
    final sequenceString = _sequence.join(' / ');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Save Possession for ${teamWithBall.name}?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sequence:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(sequenceString),
              const SizedBox(height: 16),
              // TODO: Add outcome and other details to this summary
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Call the repository method on confirm
              savePossessionToDatabase(
                teamWithBall,
                opponentTeam,
                sequenceString,
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Method to display the custom dialog for the sub
  void _showSubstitutionDialog(BuildContext context) {
    // Controllers for the text fields
    final playerInController = TextEditingController();
    final playerOutController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Substitution'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make the dialog content compact
              children: [
                TextFormField(
                  controller: playerInController,
                  decoration: const InputDecoration(
                    labelText: 'Player In',
                    prefixIcon: Icon(Icons.arrow_upward),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: playerOutController,
                  decoration: const InputDecoration(
                    labelText: 'Player Out',
                    prefixIcon: Icon(Icons.arrow_downward),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // If the form is valid, create the action string
                  final String subAction =
                      'Sub: #${playerInController.text} IN <-> #${playerOutController.text} OUT';
                  // Call the main onPressed callback to add it to the sequence
                  _onButtonPressed(subAction);
                  // Close the dialog
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTurnoverMenu() {
    // Create a map to link the user-friendly text to the backend enum value
    final Map<String, String> turnoverTypes = {
      'Out of bounds': 'TO_OUT_OF_BOUNDS',
      'Travelling': 'TO_TRAVEL',
      'Offensive foul': 'TO_OFFENSIVE_FOUL',
      '3 seconds in key': 'TO_3_SECONDS',
      '5 seconds violation':
          'TO_5_SECONDS', // NOTE: Add this to your Django model if needed
      '8 seconds violation': 'TO_8_SECONDS',
      'Shot clock violation': 'TO_SHOT_CLOCK',
      'Bad pass':
          'TO_BAD_PASS', // NOTE: Add this to your Django model if needed
      'Stolen ball': 'TO_STOLEN_BALL',
      'Technical foul':
          'TO_TECHNICAL_FOUL', // NOTE: Add this to your Django model if needed
    };

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
          ...turnoverTypes.entries.map(
            (entry) => ListTile(
              title: Text(entry.key), // Show the user-friendly key
              onTap: () {
                // Send the backend-friendly value to the sequence
                _onButtonPressed(entry.value);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFreeThrowMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Made Free Throw(s)'),
            onTap: () {
              // Use the exact value from the Django model's choices.
              _onButtonPressed('MADE_FT');
              Navigator.of(ctx).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Missed Free Throw(s)'),
            onTap: () {
              // THIS IS THE FIX:
              _onButtonPressed('MISSED_FT');
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main Column that holds the content and the sequence display
    return Column(
      children: [
        // Expanded ensures this container takes up all available space
        Expanded(
          // The FittedBox is the magic widget. It will scale its child
          // down to fit within the bounds of the Expanded parent.
          child: FittedBox(
            fit: BoxFit.contain, // Maintain aspect ratio, don't crop
            child: SizedBox(
              // We give the entire UI a fixed, ideal design size.
              // This is the "canvas" on which we build our layout.
              // We've chosen a common wide-screen dimension.
              width: 1280,
              height: 720,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // Because it has a fixed size, none of the inner widgets
                // will ever cause an overflow error.
                child: Column(
                  children: [
                    _Panel(
                      title: 'OFFENSE',
                      child: _OffensePanel(
                        onButtonPressed: _onButtonPressed,
                        phase: _phase,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'OFFENSE HALF COURT',
                              child: _HalfCourtPanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'DEFENSE',
                              child: _DefensePanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
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
                                game: widget.game,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'CONTROL',
                              child: _ControlPanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'OUTCOME',
                              child: _OutcomePanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'SHOOT',
                              child: _ShootPanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                                currentDuration: _durationInSeconds,
                                onDurationChanged: (newDuration) {
                                  setState(
                                    () => _durationInSeconds = newDuration,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _Panel(
                              title: 'TAG OFFENSIVE REBOUND',
                              child: _OffRebPanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _Panel(
                              title: 'ADVANCED',
                              child: _AdvancePanel(
                                onButtonPressed: _onButtonPressed,
                                phase: _phase,
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

  Widget _buildSequenceDisplay() {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        _sequence.isEmpty
            ? "Press Start for the new possession."
            : _sequence.join(' / '),
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 16,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

// The _ActionButton is now a StatelessWidget as it doesn't need flex
class _ActionButton extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final ValueChanged<String> onPressed;
  final int? flex;
  final double? textSize;
  final bool isEnabled;

  const _ActionButton({
    required this.text,
    this.color,
    required this.onPressed,
    this.textSize,
    this.textColor,
    this.flex,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        onPressed: isEnabled ? () => onPressed(text) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.lightBlue,
          foregroundColor: textColor ?? Colors.white,
          // Let the button fill the height provided by the TableRow
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: TextStyle(
            fontSize: textSize ?? 14,
            fontWeight: FontWeight.bold,
            height: 1.1,
            fontFamily: 'Montserrat',
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

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
          Padding(padding: const EdgeInsets.all(4.0), child: child),
        ],
      ),
    );
  }
}

class _OffensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _OffensePanel({required this.onButtonPressed, required this.phase});

  @override
  Widget build(BuildContext context) {
    final setButtonColor = Colors.green;
    // We use a Column to stack the two rows vertically
    return Column(
      children: [
        // First row
        Row(
          children: List.generate(20, (i) {
            return _ActionButton(
              text: 'Set ${i + 1}',
              color: setButtonColor,
              onPressed: onButtonPressed,
              textSize: 14,
              isEnabled: phase == PossessionLoggingPhase.active,
            );
          }),
        ),
        // Second row
        Row(
          children:
              [
                    'FastBreak',
                    'Transit',
                    '<14s',
                    'BoB 1',
                    'BoB 2',
                    'SoB 1',
                    'SoB 2',
                    'Special 1',
                    'Special 2',
                    'ATO Spec',
                  ]
                  .map(
                    (t) => Expanded(
                      child: _ActionButton(
                        text: t,
                        color: Colors.grey[400],
                        onPressed: onButtonPressed,
                        isEnabled: phase == PossessionLoggingPhase.active,
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4), // Small gap between rows
      ],
    );
  }
}

class _HalfCourtPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _HalfCourtPanel({required this.onButtonPressed, required this.phase});

  @override
  Widget build(BuildContext context) {
    // Define the colors based on your design
    final darkBlue = const Color(0xFF00008B); // A deep, solid blue
    final teal = const Color(0xFF20B2AA); // A vibrant teal/cyan

    // Data structure for the panel.
    // We're using a list of maps to hold both the text and the color for each button.
    final List<Map<String, dynamic>> buttonData = [
      {'left': 'PnR', 'right': 'Attack CloseOut', 'leftColor': darkBlue},
      {'left': 'Score', 'right': 'After Kick Out', 'leftColor': teal},
      {'left': 'Big Guy', 'right': 'After Ext Pass', 'leftColor': teal},
      {'left': '3rd Guy', 'right': 'Cuts', 'leftColor': teal},
      {'left': 'ISO', 'right': 'After Off Reb', 'leftColor': darkBlue},
      {'left': 'HighPost', 'right': 'After HandOff', 'leftColor': teal},
      {'left': 'LowPost', 'right': 'After OffScreen', 'leftColor': teal},
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: buttonData.map((rowData) {
        return TableRow(
          children: [
            // Left column button
            _ActionButton(
              text: rowData['left'],
              color: rowData['leftColor'], // Use the color from our data map
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: phase == PossessionLoggingPhase.active,
            ),
            // Right column button - always dark blue
            _ActionButton(
              text: rowData['right'],
              color: darkBlue,
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: phase == PossessionLoggingPhase.active,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DefensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _DefensePanel({required this.onButtonPressed, required this.phase});

  @override
  Widget build(BuildContext context) {
    final defColor = Colors.red[700];

    // This defines the entire layout. An empty string "" will be an empty cell.
    const List<List<String>> layout = [
      ['PnR', 'Zone', 'Zone Press', 'Other'], // Headers
      ['SWITCH', '2-3', 'Full court press', 'ISO'],
      ['DROP', '3-2', '3/4 court press', ""],
      ['HEDGE', '1-3-1', 'Half court press', ""],
      ['TRAP', '1-2-2', "", ""],
      ['ICE', 'zone', "", ""],
      ['FLAT', "", "", ""],
      ['WEAK', "", "", ""],
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      // Programmatically build the TableRows from our data structure
      children: List.generate(layout.length, (rowIndex) {
        final rowData = layout[rowIndex];
        return TableRow(
          children: List.generate(rowData.length, (colIndex) {
            final text = rowData[colIndex];

            // If it's the header row, build a Text widget
            if (rowIndex == 0) {
              return Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }

            // If the text is empty, create an empty cell
            if (text.isEmpty) {
              return const SizedBox.shrink();
            }

            // Otherwise, build an ActionButton
            return _ActionButton(
              text: text,
              color: text == 'ISO' ? Colors.red : defColor,
              onPressed: onButtonPressed,
              isEnabled: phase == PossessionLoggingPhase.active,
            );
          }),
        );
      }),
    );
  }
}

class _PlayersPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;
  final Game game;

  const _PlayersPanel({
    required this.onButtonPressed, 
    required this.phase,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    // Get players from both teams and sort by jersey number
    final homeTeamPlayers = (game.homeTeam.players ?? [])
        .where((player) => player.jerseyNumber != null)
        .toList()
      ..sort((a, b) => (a.jerseyNumber ?? 0).compareTo(b.jerseyNumber ?? 0));
    
    final awayTeamPlayers = (game.awayTeam.players)
        .where((player) => player.jerseyNumber != null)
        .toList()
      ..sort((a, b) => (a.jerseyNumber ?? 0).compareTo(b.jerseyNumber ?? 0));
    
    return Column(
      // The main axis alignment can be 'start' or 'center' depending on preference
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // --- PLAYER NUMBERS TABLE (4 rows, 6 columns) ---
        Table(
          // Use FixedColumnWidth to make all columns equal and prevent overflow
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: List.generate(4, (rowIndex) {
            return TableRow(
              children: List.generate(6, (colIndex) {
                // Determine the color based on the column
                // First 3 columns (0,1,2) are home team (yellow outline in image)
                // Last 3 columns (3,4,5) are away team (green outline in image)
                final color = colIndex < 3 ? Colors.blue[800] : Colors.black87;
                
                // Calculate player index
                final playerIndex = rowIndex * 3 + (colIndex % 3);
                String playerText = '#';
                
                if (colIndex < 3) {
                  // Home team players (first 3 columns)
                  if (playerIndex < homeTeamPlayers.length) {
                    playerText = homeTeamPlayers[playerIndex].jerseyNumber?.toString() ?? '#';
                  }
                } else {
                  // Away team players (last 3 columns)
                  if (playerIndex < awayTeamPlayers.length) {
                    playerText = awayTeamPlayers[playerIndex].jerseyNumber?.toString() ?? '#';
                  }
                }
                
                return _ActionButton(
                  text: playerText,
                  color: color,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                );
              }),
            );
          }),
        ),

        const SizedBox(height: 8), // Spacer between the two tables
        // --- ACTION BUTTONS TABLE (3 rows, 2 columns) ---
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
          children: [
            TableRow(
              children: [
                _ActionButton(
                  text: 'BoxOut -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
                _ActionButton(
                  text: 'Substitution',
                  color: Colors.black,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'DefReb +1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
                _ActionButton(
                  text: 'Recover -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'OffReb -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
                const SizedBox.shrink(), // Empty cell for the bottom right
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _ControlPanel({required this.onButtonPressed, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween ensures space between tables
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // --- TABLE 1 (Start / Period) ---
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Give START more space
            1: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              children: [
                _ActionButton(
                  text: 'START',
                  color: Colors.green,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.inactive,
                ),
              ],
            ),
          ],
        ),

        // --- TABLE 2 (Off / Def / Undo) ---
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                _ActionButton(
                  text: 'Off',
                  color: Colors.blueAccent,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.awaitingTeam,
                ),
                _ActionButton(
                  text: 'Def',
                  color: Colors.green,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.awaitingTeam,
                ),
                _ActionButton(
                  text: 'UNDO',
                  color: Colors.grey,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
              ],
            ),
          ],
        ),

        // --- TABLE 3 (End / Forward) ---
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Give END more space
            1: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              children: [
                _ActionButton(
                  text: 'END',
                  color: Colors.red,
                  onPressed: onButtonPressed,
                  isEnabled:
                      phase == PossessionLoggingPhase.active ||
                      phase == PossessionLoggingPhase.awaitingTeam,
                ),
                // _ActionButton(
                //   text: 'FORW',
                //   color: Colors.grey,
                //   onPressed: onButtonPressed,
                //   isEnabled: isEnabled,
                // ), // TODO: Implement REDO functionality for the next release.
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase; // Accept the enum

  const _OutcomePanel({required this.onButtonPressed, required this.phase});

  Widget buildHeader(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.black,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool isAwaitingShotResult =
        phase == PossessionLoggingPhase.awaitingShotResult;
    final bool isActive = phase == PossessionLoggingPhase.active;

    return Column(
      // Define the relative widths of the 4 content columns
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Give START more space
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              children: [
                _ActionButton(
                  text: 'Lay Up',
                  color: Colors.orangeAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
                _ActionButton(
                  text: 'Shot',
                  color: Colors.orangeAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
                _ActionButton(
                  text: 'Turnover',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: '2pts',
                  color: Colors.deepOrangeAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
                _ActionButton(
                  text: '3pts',
                  color: Colors.deepOrangeAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
                _ActionButton(
                  text: 'Foul',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'Made',
                  color: Colors.green,
                  onPressed: onButtonPressed,
                  isEnabled: isAwaitingShotResult,
                ),
                _ActionButton(
                  text: 'Missed',
                  color: Colors.red,
                  onPressed: onButtonPressed,
                  isEnabled: isAwaitingShotResult,
                ),
                _ActionButton(
                  text: 'Free Throw',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
                  isEnabled: isActive,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ShootPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;
  final double currentDuration;
  final ValueChanged<double> onDurationChanged;

  const _ShootPanel({
    required this.onButtonPressed,
    required this.phase,
    required this.currentDuration,
    required this.onDurationChanged,
  });
  @override
  Widget build(BuildContext context) {
    Widget buildHeader(String text) => Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- LEFT COLUMN: OffReb Tag ---
        Expanded(
          flex: 2, // Give this section more space
          child: Column(
            children: [
              buildHeader('Shoot Quality'),
              Row(
                children: [
                  _ActionButton(
                    text: 'SQ:1',
                    color: Colors.green,
                    onPressed: onButtonPressed,
                    isEnabled: phase == PossessionLoggingPhase.active,
                  ),
                  _ActionButton(
                    text: 'SQ:2',
                    color: Colors.orangeAccent,
                    onPressed: onButtonPressed,
                    isEnabled: phase == PossessionLoggingPhase.active,
                  ),
                  _ActionButton(
                    text: 'SQ:3',
                    color: Colors.red,
                    onPressed: onButtonPressed,
                    isEnabled: phase == PossessionLoggingPhase.active,
                  ),
                ],
              ),
              buildHeader('Shoot time'),
              // Row(
              //   children: [
              //     _ActionButton(
              //       text: '< 4s',
              //       color: Colors.blueGrey,
              //       onPressed: onButtonPressed,
              //       isEnabled: isEnabled,
              //     ),
              //     _ActionButton(
              //       text: '4-7s',
              //       color: Colors.indigo,
              //       onPressed: onButtonPressed,
              //       isEnabled: isEnabled,
              //     ),
              //     _ActionButton(
              //       text: '8-14s',
              //       color: Colors.indigo,
              //       onPressed: onButtonPressed,
              //       isEnabled: isEnabled,
              //     ),
              //     _ActionButton(
              //       text: '15-20s',
              //       color: Colors.indigo,
              //       onPressed: onButtonPressed,
              //       isEnabled: isEnabled,
              //     ),
              //   ],
              // ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Duration: ${currentDuration.toStringAsFixed(0)}s",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: currentDuration,
                    min: 1,
                    max: 24,
                    divisions: 23, // 23 divisions create 24 distinct steps
                    label: currentDuration.toStringAsFixed(0),
                    onChanged: phase == PossessionLoggingPhase.active
                        ? onDurationChanged
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OffRebPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _OffRebPanel({required this.onButtonPressed, required this.phase});

  @override
  Widget build(BuildContext context) {
    final offRebTagColor = Colors.pink[300];

    return Column(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween, //ensures space between tables
      children: [
        Table(
          // Define the relative widths of the 4 content columns
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(2), // Give START more space
          },
          // Set default height for all rows
          children: [
            // --- HEADER ROW ---
            TableRow(
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  // Set default height for all rows
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        _ActionButton(
                          text: 'TOR:0',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                        _ActionButton(
                          text: 'TOR:1',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                        _ActionButton(
                          text: 'TOR:2',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                      ],
                    ), // TableRow
                    TableRow(
                      children: [
                        _ActionButton(
                          text: 'TOR:3',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                        _ActionButton(
                          text: 'TOR:4',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                        _ActionButton(
                          text: 'TOR:5',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                          isEnabled: phase == PossessionLoggingPhase.active,
                        ),
                      ],
                    ), // TableRow
                  ],
                ),
              ],
            ), // TableRow
            // --- BUTTON ROWS ---
            TableRow(
              children: [
                _ActionButton(
                  text: 'Yes',
                  color: Colors.green,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
              ],
            ), // TableRow
            TableRow(
              children: [
                _ActionButton(
                  text: 'No',
                  color: Colors.red,
                  onPressed: onButtonPressed,
                  isEnabled: phase == PossessionLoggingPhase.active,
                ),
              ],
            ), // TableRow
          ],
        ),
      ],
    );
  }
}

class _AdvancePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final PossessionLoggingPhase phase;

  const _AdvancePanel({
    super.key,
    required this.onButtonPressed,
    required this.phase, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    // Define the colors based on your design
    final indigoBlue = Colors.indigoAccent; // A deep, solid blue
    final stealColor = Colors.redAccent; // A vibrant teal/cyan

    // Data structure for the panel.
    // We're using a list of maps to hold both the text and the color for each button.
    final List<Map<String, dynamic>> buttonData = [
      {'left': 'Paint Touch', 'right': 'Steal', 'rightColor': stealColor},
      {'left': 'Kick Out', 'right': 'Deny / +1', 'rightColor': stealColor},
      {'left': 'Extra Pass', 'right': 'After TO', 'leftColor': Colors.black},
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: buttonData.map((rowData) {
        return TableRow(
          children: [
            // Left column button
            _ActionButton(
              text: rowData['left'],
              color: indigoBlue, // Use the color from our data map
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: phase == PossessionLoggingPhase.active,
            ),
            // Right column button - always dark blue
            _ActionButton(
              text: rowData['right'],
              color: rowData['rightColor'], // Use the color from our data map,
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: phase == PossessionLoggingPhase.active,
            ),
          ],
        );
      }).toList(),
    );
  }
}
