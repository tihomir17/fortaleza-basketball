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
    return BlocProvider(
      create: (context) => sl<GameDetailCubit>()
        ..fetchGameDetails(
          token: context.read<AuthCubit>().state.token!,
          gameId: gameId,
        ),
      // We wrap the Scaffold in a BlocBuilder to get the game data for the AppBar
      child: BlocBuilder<GameDetailCubit, GameDetailState>(
        builder: (context, state) {
          final game = state.game;

          // Determine the title for the AppBar
          final String appBarTitle = game != null
              ? '${game.homeTeam.name} vs ${game.awayTeam.name}'
              : 'Possession Logger';

          return Scaffold(
            // Use our custom AppBar that can handle the menu toggle
            appBar: UserProfileAppBar(title: appBarTitle),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state.status == GameDetailStatus.loading) {
                          return const Center(
                            child: Text("Loading Game Data..."),
                          );
                        }
                        if (state.status == GameDetailStatus.failure ||
                            game == null) {
                          return Center(
                            child: Text(
                              state.errorMessage ??
                                  "Error: Could not load game data.",
                            ),
                          );
                        }

                        // Once the game is loaded, build the main UI
                        return _LiveTrackingView(game: game);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // A new helper widget to build the score display
  Widget _buildScoreHeader(BuildContext context, Game game) {
    final theme = Theme.of(context);
    final homeScore = game.homeTeamScore ?? 0;
    final awayScore = game.awayTeamScore ?? 0;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${game.homeTeam.name} ', style: theme.textTheme.titleMedium),
          Text(
            '$homeScore',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Anton',
              color: theme.colorScheme.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text('-', style: theme.textTheme.titleMedium),
          ),
          Text(
            '$awayScore',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Anton',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(game.awayTeam.name, style: theme.textTheme.titleMedium),
        ],
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
                              title: 'DEFENSE',
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
  final int? flex;

  const _ActionButton({
    required this.text,
    this.color,
    this.textColor,
    required this.onPressed,
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        onPressed: () => onPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.lightBlue,
          foregroundColor: textColor ?? Colors.white,
          // Let the button fill the height provided by the TableRow
          // minimumSize: const Size.fromHeight(32),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    final setButtonColor = Colors.green;
    // We use a Column to stack the two rows vertically
    return Column(
      children: [
        // --- First ROW ---
        Row(
          children: List.generate(12, (i) {
            return _ActionButton(
              text: 'Set ${i + 1}',
              color: setButtonColor,
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
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Transit',
              color: Colors.grey[400],
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '<14s',
              color: Colors.grey[400],
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'BoB 1',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'BoB 2',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'SoB 1',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'SoB 2',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Special',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Special',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'ATO Spec',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Set 13',
              color: setButtonColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Set 14',
              color: setButtonColor,
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
    final darkBlue = Colors.blue[900];
    // Table is good for this kind of rigid layout
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2)},
      // Set default height for all rows
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            _ActionButton(
              text: 'PnR',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Attack Close-Out',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'Score',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'After Kick Out',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Big Guy', onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Extra Pass',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: '3rd Guy', onPressed: onButtonPressed),
            _ActionButton(
              text: 'Cuts',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'ISO',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'After Off Reb',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'HighPost', onPressed: onButtonPressed),
            _ActionButton(
              text: 'After HandOff',
              color: darkBlue,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'LowPost', onPressed: onButtonPressed),
            _ActionButton(
              text: 'After Off-Screen',
              color: darkBlue,
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

    // Helper for column headers
    Widget buildHeader(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black,
      ),
    );

    // Helper for empty cells to create spacing
    Widget emptyCell() => const SizedBox.shrink();

    return Table(
      // Define the relative widths of the 4 content columns
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      // Set default height for all rows
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // --- HEADER ROW ---
        // TableRow(
        //   children: [
        //     buildHeader('PnR'),
        //     buildHeader('Zone'),
        //     buildHeader('Zone Press'),
        //     buildHeader('Other'),
        //   ],
        // ),
        // --- BUTTON ROWS ---
        TableRow(
          children: [
            _ActionButton(
              text: 'SWITCH',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '2-3',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Zone Press',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'ISO',
              color: Colors.red,
              onPressed: onButtonPressed,
            ),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'DROP',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '3-2',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Zone Press',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(), // No button in this cell
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'HEDGE',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '1-3-1',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'Zone Press',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'TRAP',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: '1-2-2',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(),
            emptyCell(),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'ICE',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            _ActionButton(
              text: 'zone',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(),
            emptyCell(),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'FLAT',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(),
            emptyCell(),
            emptyCell(),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'WEAK',
              color: defColor,
              onPressed: onButtonPressed,
            ),
            emptyCell(),
            emptyCell(),
            emptyCell(),
          ],
        ),
      ],
    );
  }
}

// class _PlayersPanel extends StatelessWidget {
//   final ValueChanged<String> onButtonPressed;
//   const _PlayersPanel({required this.onButtonPressed});
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Text(
//           "Home / Away",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         GridView.count(
//           crossAxisCount: 12, // 12 players per team
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           children: List.generate(
//             24,
//             (i) => _ActionButton(
//               text: '#',
//               color: i < 12 ? Colors.blue[800] : Colors.grey[800],

//               onPressed: onButtonPressed,
//             ),
//           ),
//         ),
//         const SizedBox(height: 2),
//         Wrap(
//           spacing: 4,
//           runSpacing: 4,
//           children:
//               [
//                     'BoxOut -1',
//                     'DefReb +1',
//                     'OffReb -1',
//                     'Substitution',
//                     'Recover -1',
//                   ]
//                   .map(
//                     (t) => _ActionButton(
//                       text: t,
//                       color: Colors.purple,

//                       onPressed: onButtonPressed,
//                     ),
//                   )
//                   .toList(),
//         ),
//       ],
//     );
//   }
// }

class _PlayersPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _PlayersPanel({required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
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
                final color = colIndex < 3 ? Colors.blue[800] : Colors.black87;
                // You will replace "#" with real player numbers later
                return _ActionButton(
                  text: '#',
                  color: color,
                  onPressed: onButtonPressed,
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
                ),
                _ActionButton(
                  text: 'Substitution',
                  color: Colors.black,
                  onPressed: onButtonPressed,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'DefReb +1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: 'Recover -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'OffReb -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
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

              onPressed: onButtonPressed,
            ),
            _ActionButton(text: 'Period', onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Off', onPressed: onButtonPressed),
            _ActionButton(text: 'Def', onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(
              text: 'END',
              color: Colors.red,

              onPressed: onButtonPressed,
            ),
            _ActionButton(text: 'FORW', onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            const SizedBox.shrink(),
            _ActionButton(text: 'UNDO', onPressed: onButtonPressed),
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
      children: [
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
      ].map((t) => _ActionButton(text: t, onPressed: onButtonPressed)).toList(),
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
      children: [
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
      ].map((t) => _ActionButton(text: t, onPressed: onButtonPressed)).toList(),
    );
  }
}
