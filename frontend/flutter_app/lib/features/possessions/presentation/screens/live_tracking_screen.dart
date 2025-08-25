// lib/features/possessions/presentation/screens/live_tracking_screen.dart

// ignore_for_file: unused_import, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_cubit.dart';
import 'package:flutter_app/features/games/presentation/cubit/game_detail_state.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  bool _isSessionActive = false;

  void _onButtonPressed(String action) {
    // --- SPECIAL BUTTON LOGIC ---
    if (action == 'Turnover') {
      _showTurnoverMenu();
      return;
    }
    if (action == 'Free Throw') {
      _showFreeThrowMenu();
      return;
    }

    setState(() {
      if (action == 'START') {
        _isSessionActive = true;
        _sequence = []; // Clear the sequence for a new possession
        return; // Do not add "START" to the sequence list
      }

      if (action == 'END') {
        _isSessionActive = false;
        // Optionally, you could add "END" to the sequence here if you want
        // _sequence.add(action);
        // TODO: Trigger the save possession logic
        return;
      }

      if (!_isSessionActive) return;

      if (action == "UNDO" && _sequence.isNotEmpty) {
        _sequence.removeLast();
      } else if (action != "UNDO") {
        _sequence.add(action);
      }
    });
  }

  void _showTurnoverMenu() {
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
          ...[
            'Out of bounds',
            'Travelling',
            'Offensive foul',
            '3 seconds in key',
            '5 seconds violation',
            '8 seconds violation',
            'Shot clock violation',
            'Bad pass',
            'Technical foul',
          ].map(
            (type) => ListTile(
              title: Text(type),
              onTap: () {
                // Add the specific turnover type to the sequence
                _onButtonPressed('TO: $type');
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
            title: const Text('Made'),
            onTap: () {
              _onButtonPressed('FT Made');
              Navigator.of(ctx).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Missed'),
            onTap: () {
              _onButtonPressed('FT Miss');
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
                        isEnabled: _isSessionActive,
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
                                isEnabled: _isSessionActive,
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
                                isEnabled: _isSessionActive,
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
                                isEnabled: _isSessionActive,
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
                                isEnabled: _isSessionActive,
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
                                isEnabled: _isSessionActive,
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
            ? "Press Start for the new possesion."
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
  final double? textSize;
  final bool isEnabled;

  const _ActionButton({
    required this.text,
    this.color,
    required this.onPressed,
    this.textSize,
    this.textColor,
    this.flex,
    this.isEnabled = true,
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
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _OffensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final bool isEnabled;

  const _OffensePanel({required this.onButtonPressed, required this.isEnabled});

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
              textSize: 14,
              isEnabled: isEnabled,
            );
          }),
        ),
        // --- Second row ---
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
                    'Set 13',
                    'Set 14',
                  ]
                  .map(
                    (t) => Expanded(
                      child: _ActionButton(
                        text: t,
                        color: Colors.grey[400],
                        onPressed: onButtonPressed,
                        isEnabled: isEnabled, // <-- PASS THE STATE
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
  final bool isEnabled;

  const _HalfCourtPanel({
    required this.onButtonPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    // Define the colors based on your design
    final darkBlue = const Color(0xFF00008B); // A deep, solid blue
    final teal = const Color(0xFF20B2AA); // A vibrant teal/cyan

    // Data structure for the panel.
    // We're using a list of maps to hold both the text and the color for each button.
    final List<Map<String, dynamic>> buttonData = [
      {'left': 'PnR', 'right': 'Att. CloseOut', 'leftColor': darkBlue},
      {'left': 'Score', 'right': 'Aft. Kick Out', 'leftColor': teal},
      {'left': 'Big Guy', 'right': 'Aft. Ext Pass', 'leftColor': teal},
      {'left': '3rd Guy', 'right': 'Cuts', 'leftColor': teal},
      {'left': 'ISO', 'right': 'Aft. Off Reb', 'leftColor': darkBlue},
      {'left': 'HighPost', 'right': 'Aft. HandOff', 'leftColor': teal},
      {'left': 'LowPost', 'right': 'Aft. OffScreen', 'leftColor': teal},
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
              isEnabled: isEnabled,
            ),
            // Right column button - always dark blue
            _ActionButton(
              text: rowData['right'],
              color: darkBlue,
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: isEnabled,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DefensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final bool isEnabled;

  const _DefensePanel({required this.onButtonPressed, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final defColor = Colors.red[700];

    // This defines the entire layout. An empty string "" will be an empty cell.
    const List<List<String>> layout = [
      ['PnR', 'Zone', 'Zone Press', 'Other'], // Headers
      ['SWITCH', '2-3', 'Zone Press', 'ISO'],
      ['DROP', '3-2', 'Zone Press', ""],
      ['HEDGE', '1-3-1', 'Zone Press', ""],
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
              isEnabled: isEnabled,
            );
          }),
        );
      }),
    );
  }
}

class _PlayersPanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  final bool isEnabled;

  const _PlayersPanel({required this.onButtonPressed, required this.isEnabled});

  // Method to display the custom dialog for the sub
  void _showSubstitutionDialog(BuildContext context) {
    // Controllers for the text fields
    final playerInController = TextEditingController();
    final playerOutController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (isEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Substitution'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Make the dialog content compact
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
                    onButtonPressed(subAction);
                    // Close the dialog
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      Center(
        child: Text("Logging is inactive. Press start to log new possession."),
      );
    }
  }

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
                  isEnabled: isEnabled,
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
                  isEnabled: isEnabled,
                ),
                Padding(
                  // Wrap in Padding to match the _ActionButton style
                  padding: const EdgeInsets.all(1.0),
                  child: ElevatedButton(
                    onPressed: () => _showSubstitutionDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Substitution'),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'DefReb +1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
                ),
                _ActionButton(
                  text: 'Recover -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'OffReb -1',
                  color: Colors.purple,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
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
  final bool isEnabled;

  const _ControlPanel({required this.onButtonPressed, required this.isEnabled});

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
                  color: Colors.grey,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
                ),
                _ActionButton(
                  text: 'Def',
                  color: Colors.grey,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
                ),
                _ActionButton(
                  text: 'UNDO',
                  color: Colors.grey,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled, // TODO: UNDO MUST BE ALWAYS ACTIVE!
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
                  isEnabled: isEnabled,
                ),
                _ActionButton(
                  text: 'FORW',
                  color: Colors.grey,
                  onPressed: onButtonPressed,
                  isEnabled: isEnabled,
                ),
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
  const _OutcomePanel({required this.onButtonPressed});

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
                ),
                _ActionButton(
                  text: 'Shot',
                  color: Colors.orangeAccent,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: 'Turnover',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: '2pts',
                  color: Colors.deepOrangeAccent,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: '3pts',
                  color: Colors.deepOrangeAccent,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: 'Foul',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
                ),
              ],
            ),
            TableRow(
              children: [
                _ActionButton(
                  text: 'Made',
                  color: Colors.green,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: 'Miss',
                  color: Colors.red,
                  onPressed: onButtonPressed,
                ),
                _ActionButton(
                  text: 'Free Throw',
                  color: Colors.redAccent,
                  onPressed: onButtonPressed,
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
  const _ShootPanel({required this.onButtonPressed});

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
                    text: '1',
                    color: Colors.green,
                    onPressed: onButtonPressed,
                  ),
                  _ActionButton(
                    text: '2',
                    color: Colors.orangeAccent,
                    onPressed: onButtonPressed,
                  ),
                  _ActionButton(
                    text: '3',
                    color: Colors.red,
                    onPressed: onButtonPressed,
                  ),
                ],
              ),
              buildHeader('Shoot time'),
              Row(
                children: [
                  _ActionButton(
                    text: '< 4s',
                    color: Colors.blueGrey,
                    onPressed: onButtonPressed,
                  ),
                  _ActionButton(
                    text: '4-8s',
                    color: Colors.indigo,
                    onPressed: onButtonPressed,
                  ),
                  _ActionButton(
                    text: '8-14s',
                    color: Colors.indigo,
                    onPressed: onButtonPressed,
                  ),
                  _ActionButton(
                    text: '14-20s',
                    color: Colors.indigo,
                    onPressed: onButtonPressed,
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
  const _OffRebPanel({required this.onButtonPressed});

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
                          text: '0',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                        ),
                        _ActionButton(
                          text: '1',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                        ),
                        _ActionButton(
                          text: '2',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                        ),
                      ],
                    ), // TableRow
                    TableRow(
                      children: [
                        _ActionButton(
                          text: '3',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                        ),
                        _ActionButton(
                          text: '4',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
                        ),
                        _ActionButton(
                          text: '5',
                          color: offRebTagColor,
                          onPressed: onButtonPressed,
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
                ),
              ],
            ), // TableRow
            TableRow(
              children: [
                _ActionButton(
                  text: 'No',
                  color: Colors.red,
                  onPressed: onButtonPressed,
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
  final bool isEnabled; // Add the isEnabled flag

  const _AdvancePanel({
    super.key,
    required this.onButtonPressed,
    required this.isEnabled, // Add to constructor
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
              isEnabled: isEnabled,
            ),
            // Right column button - always dark blue
            _ActionButton(
              text: rowData['right'],
              color: rowData['rightColor'], // Use the color from our data map,
              textColor: Colors.white,
              onPressed: onButtonPressed,
              isEnabled: isEnabled,
            ),
          ],
        );
      }).toList(),
    );
  }
}
