// lib/features/possessions/presentation/screens/live_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_state.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveTrackingScreen extends StatelessWidget {
  final int gameId;
  const LiveTrackingScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    // We now wrap the entire screen in a BlocProvider for the GameDetailCubit
    return BlocProvider(
      create: (context) => sl<GameDetailCubit>()
        ..fetchGameDetails(
          token: context.read<AuthCubit>().state.token!,
          gameId: gameId,
        ),
      child: Scaffold(
        appBar: const UserProfileAppBar(title: 'Game logger'),
        body: SafeArea(
          // We use a BlocBuilder to wait for the game data to load
          child: BlocBuilder<GameDetailCubit, GameDetailState>(
            builder: (context, state) {
              if (state.status == GameDetailStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == GameDetailStatus.failure ||
                  state.game == null) {
                return const Center(
                  child: Text("Error: Could not load game data."),
                );
              }

              // Once the game is loaded, we build the main UI
              final game = state.game!;
              return _LiveTrackingView(
                game: game,
              ); // Pass the loaded game to the view
            },
          ),
        ),
      ),
    );
  }
}

// Extract the main UI into its own StatefulWidget to manage its local state
class _LiveTrackingView extends StatefulWidget {
  final Game game;
  const _LiveTrackingView({required this.game});

  @override
  _LiveTrackingViewState createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView> {
  final List<String> _sequence = [];

  void _onButtonPressed(String action) {
    setState(() {
      if (action == "UNDO" && _sequence.isNotEmpty) {
        _sequence.removeLast();
      } else if (action != "UNDO") {
        _sequence.add(action);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            // This Expanded is the key to preventing all layout errors.
            // It gives the main content area a finite height.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // --- TOP ROW: OFFENSE (fixed height) ---
                    _Panel(
                      title: 'OFFENSE',
                      child: _OffensePanel(onButtonPressed: _onButtonPressed),
                    ),
                    const SizedBox(height: 8),

                    // --- MIDDLE ROW: HALF COURT, DEFENSE, PLAYERS ---
                    // This row is expanded to fill the remaining vertical space
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Each panel is in an Expanded widget to control its width
                          Expanded(
                            flex: 4, // Adjust flex to control relative widths
                            child: _Panel(
                              title: 'OFFENSE HALF COURT',
                              child: _HalfCourtPanel(
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'DEFFENCE',
                              child: _DefensePanel(
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              title: 'PLAYERS',
                              child: _PlayersPanel(
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- BOTTOM ROW: CONTROL, OUTCOME, ADVANCE (fixed height) ---
                    IntrinsicHeight(
                      // Ensures all panels in this row are the same height
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _Panel(
                              title: 'CONTROL',
                              child: _ControlPanel(
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'OUTCOME',
                              child: _OutcomePanel(
                                onButtonPressed: _onButtonPressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _Panel(
                              title: 'ADVANCE',
                              child: _AdvancePanel(
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
            _buildSequenceDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceDisplay() {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        _sequence.isEmpty ? "start - ..." : _sequence.join(' / '),
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
          Padding(padding: const EdgeInsets.all(4.0), child: child),
        ],
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
  final int flex;

  const _ActionButton({
    required this.text,
    this.color,
    this.textColor,
    required this.flex,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        onPressed: () => onPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.grey[300],
          foregroundColor: textColor ?? Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
      ),
    );
  }
}

class _OffensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _OffensePanel({required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    // We use a Column to stack the two rows vertically
    return Column(
      children: [
        // --- First ROW ---
        Row(
          children: List.generate(12, (i) {
            return _ActionButton(
              text: 'Set ${i + 1}',
              color: Colors.green,
              flex: 1, // All buttons in this row have equal width
              onPressed: onButtonPressed,
            );
          }),
        ),
        // --- Second row ---
        Row(
          children: [
            _ActionButton(
              text: 'FastBreak',
              color: Colors.grey[400],
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Transit',
              color: Colors.grey[400],
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '<14s',
              color: Colors.grey[400],
              flex: 1,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'BoB 1',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'BoB 2',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'SoB 1',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'SoB 2',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Special',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Special',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'ATO Spec',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Set 13',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Set 14',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        const SizedBox(height: 4), // Small gap between rows
      ],
    );
  }
}

class _HalfCourtPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _HalfCourtPanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    // Table is good for this kind of rigid layout
    return Table(
      children: [
        TableRow(
          children: [
            _ActionButton(text: 'PnR', flex: 2, onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Close-Out',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Score', flex: 2, onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Kick Out',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Big Guy', flex: 2, onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Extra Pass',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: '3rd Guy', flex: 2, onPressed: onButtonPressed),
            _ActionButton(text: 'Cuts', flex: 2, onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'ISO', flex: 2, onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Off Reb',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'HighPost',
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'After HandOff',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'LowPost', flex: 2, onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Off-Screen',
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _DefensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _DefensePanel({required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    final defColor = Colors.red[700];

    // Helper widget for the column headers
    Widget buildHeader(String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- COLUMN 1: PnR ---
        Expanded(
          flex: 2, // Give it a bit more space
          child: Column(
            children: [
              buildHeader('PnR'),
              ...['SWITCH', 'DROP', 'HEDGE', 'TRAP', 'ICE', 'FLAT', '/']
                  .map(
                    (t) => _ActionButton(
                      text: t,
                      color: defColor,
                      onPressed: onButtonPressed,
                      flex: 2,
                    ),
                  )
                  ,
            ],
          ),
        ),

        // --- COLUMN 2: Zone ---
        Expanded(
          flex: 2,
          child: Column(
            children: [
              buildHeader('Zone'),
              ...['2-3', '3-2', '1-3-1', '1-2-2', 'zone']
                  .map(
                    (t) => _ActionButton(
                      text: t,
                      color: defColor,
                      onPressed: onButtonPressed,
                      flex: 2,
                    ),
                  )
                  ,
            ],
          ),
        ),

        // --- COLUMN 3: Zone Press ---
        Expanded(
          flex: 3, // Give it more space as the text is longer
          child: Column(
            children: [
              buildHeader('Zone Press'),
              // We create three identical buttons here
              _ActionButton(
                text: 'Zone Press',
                color: defColor,
                onPressed: onButtonPressed,
                flex: 2,
              ),
              _ActionButton(
                text: 'Zone Press',
                color: defColor,
                onPressed: onButtonPressed,
                flex: 2,
              ),
              _ActionButton(
                text: 'Zone Press',
                color: defColor,
                onPressed: onButtonPressed,
                flex: 2,
              ),
            ],
          ),
        ),

        // --- COLUMN 4: Other ---
        Expanded(
          flex: 2,
          child: Column(
            children: [
              buildHeader('Other'),
              _ActionButton(
                text: 'ISO',
                color: Colors.red,
                onPressed: onButtonPressed,
                flex: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayersPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _PlayersPanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Home / Away",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        GridView.count(
          crossAxisCount: 12, // 12 players per team
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            24,
            (i) => _ActionButton(
              text: '#',
              color: i < 12 ? Colors.blue[800] : Colors.grey[800],
              flex: 2,
              onPressed: onButtonPressed,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children:
              [
                    'BoxOut -1',
                    'DefReb +1',
                    'OffReb -1',
                    'Substitution',
                    'Recover -1',
                  ]
                  .map(
                    (t) => _ActionButton(
                      text: t,
                      color: Colors.purple,
                      flex: 2,
                      onPressed: onButtonPressed,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _ControlPanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(
          children: [
            _ActionButton(
              text: 'START',
              color: Colors.green,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(text: 'Period', flex: 2, onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Off', flex: 2, onPressed: onButtonPressed),
            _ActionButton(text: 'Def', flex: 2, onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'END',
              color: Colors.red,
              flex: 2,
              onPressed: onButtonPressed,
            ),
            _ActionButton(text: 'FORW', flex: 2, onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            const SizedBox.shrink(),
            _ActionButton(text: 'UNDO', flex: 2, onPressed: onButtonPressed),
          ],
        ),
      ],
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _OutcomePanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          [
                'Lay Up',
                'Shot',
                'Turnov',
                '2pt',
                '3pt',
                'Foul',
                'Made',
                'Miss',
                'Ft',
                'ShotQuality',
                '<4s',
                '4-8s',
                '8-14s',
                '14-20s',
              ]
              .map(
                (t) =>
                    _ActionButton(text: t, flex: 2, onPressed: onButtonPressed),
              )
              .toList(),
    );
  }
}

class _AdvancePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _AdvancePanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          [
                'OffReb Tag',
                '0',
                '1',
                '2',
                '3',
                '4',
                'Yes',
                'No',
                'Paint Touch',
                'Kick Out',
                'Extra Pass',
                'Steal',
                'Deny / +1',
                'After TimeOut',
              ]
              .map(
                (t) =>
                    _ActionButton(text: t, flex: 2, onPressed: onButtonPressed),
              )
              .toList(),
    );
  }
}
