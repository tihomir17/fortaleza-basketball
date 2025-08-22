// lib/features/possessions/presentation/screens/live_tracking_screen.dart

// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  List<String> _sequence = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Possession Logger"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4.0),
              child: _buildButtonPanels(),
            ),
          ),
          _buildSequenceDisplay(),
        ],
      ),
    );
  }

  Widget _buildButtonPanels() {
    // Define colors
    final offColor = Colors.green[600];
    final defColor = Colors.red[700];
    final neutralColor = Colors.grey[600];
    final accentColor = Colors.blue[700];
    final playerColor = Colors.purple[700];
    final opponentColor = Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Left Column ---
        Expanded(
          flex: 10,
          child: Column(
            children: [
              _Panel(
                title: "Fast Break / Transition",
                child: _ActionButtonGrid(
                  buttons: [
                    "Fast Break",
                    "Under 14s",
                    "Transition",
                    "Set 1",
                    "Set 2",
                    "Set 3",
                  ],
                  crossAxisCount: 3,
                  buttonHeight: 145,
                  backgroundColor: offColor,
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: "Half Court Offense",
                child: _ActionButtonGrid(
                  buttons: [
                    "PnR",
                    "1x1",
                    "Score",
                    "Big Guy",
                    "3rd Guy",
                    "HP",
                    "LP",
                    "Att. ClosOut",
                    "Cuts",
                    "Aft. Ext Pass",
                    "Aft. Off Reb",
                    "Aft. Kick Out",
                    "HandOff",
                    "OffScreen",
                    "PnR",
                    "45",
                    "top",
                    "60",
                  ],
                  crossAxisCount: 4,
                  buttonHeight: 145,
                  backgroundColor: offColor,
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: "Actions",
                child: _ActionButtonGrid(
                  buttons: [
                    "Sprint",
                    "-1",
                    "Box Out",
                    "-1",
                    "OR Allow",
                    "+1",
                    "Player",
                    "In",
                    "Out",
                    "Def Reb",
                    "Steal",
                  ],
                  crossAxisCount: 4,
                  buttonHeight: 145,
                  backgroundColor: neutralColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // --- Middle Column ---
        Expanded(
          flex: 10,
          child: Column(
            children: [
              _Panel(
                title: "Defense",
                child: _ActionButtonGrid(
                  buttons: [
                    "PnR Drop",
                    "PnR Hedge",
                    "PnR Switch",
                    "PnR Ice",
                    "PnR Trap",
                    "Zone",
                    "2-3",
                    "3-2",
                    "1-3-1",
                    "Zone Press",
                    "1x1",
                    "Deny / +1",
                  ],
                  crossAxisCount: 4,
                  buttonHeight: 145,
                  backgroundColor: defColor,
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: "Outcomes",
                child: _ActionButtonGrid(
                  buttons: [
                    "Lay Up",
                    "2pt",
                    "Shot",
                    "3pt",
                    "TO",
                    "Foul",
                    "Ft",
                    "1",
                    "0",
                    "SQ",
                    "2",
                    "3",
                  ],
                  crossAxisCount: 4,
                  buttonHeight: 145,
                  backgroundColor: accentColor,
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: "Controls",
                child: _ActionButtonGrid(
                  buttons: ["START", "O", "D", "END", "Qt", "UNDO", "FORW"],
                  crossAxisCount: 3,
                  buttonHeight: 145,
                  backgroundColor: neutralColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // --- Right Column ---
        Expanded(
          flex: 10,
          child: Column(
            children: [
              _Panel(
                title: "Fortaleza",
                child: _ActionButtonGrid(
                  buttons: List.generate(12, (i) => "#"),
                  crossAxisCount: 4,
                  buttonHeight: 150,
                  backgroundColor: playerColor,
                ),
              ),
              const SizedBox(height: 10),
              _Panel(
                title: "Opponent team",
                child: _ActionButtonGrid(
                  buttons: List.generate(12, (i) => "#"),
                  crossAxisCount: 4,
                  buttonHeight: 150,
                  backgroundColor: opponentColor,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  // The black bar at the bottom for displaying the sequence
  Widget _buildSequenceDisplay() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _sequence.isEmpty ? "start - ..." : _sequence.join(' / '),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // We can add other controls like a timer here later
        ],
      ),
    );
  }
}

// A reusable Panel widget with a title
class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[700],
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(padding: const EdgeInsets.all(8.0), child: child),
        ],
      ),
    );
  }
}

// A reusable widget to create a grid of buttons
class _GridButtons extends StatelessWidget {
  final List<String> buttons;
  final int crossAxisCount; // How many columns the grid should have
  final double childAspectRatio; // The ratio of width to height for each button
  final Color? backgroundColor; // Optional custom color for the buttons

  const _GridButtons({
    required this.buttons,
    this.crossAxisCount = 3, // Default to 3 columns
    this.childAspectRatio = 2.0, // Default to a wide button
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: buttons.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return ElevatedButton(
          onPressed: () {
            // TODO: Add logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                backgroundColor ??
                Theme.of(context).primaryColor.withOpacity(0.8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(4), // Add some padding
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(
            buttons[index],
            textAlign: TextAlign.center, // Center the text
          ),
        );
      },
    );
  }
}

class _PlayerGrid extends StatelessWidget {
  final List<String> players; // Can be numbers or names later
  final Color buttonColor;
  final Color textColor;

  const _PlayerGrid({
    required this.players,
    required this.buttonColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        // Make the buttons much smaller and square
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: players.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return SizedBox(
          // Constrain the size of the button
          width: 30,
          height: 30,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.zero, // Remove default padding
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(players[index]),
          ),
        );
      },
    );
  }
}

class _ActionButtonGrid extends StatelessWidget {
  final List<String> buttons;
  final int crossAxisCount;
  final double buttonHeight;
  final Color? backgroundColor;

  const _ActionButtonGrid({
    required this.buttons,
    required this.crossAxisCount,
    this.buttonHeight = 30.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio:
          (MediaQuery.of(context).size.width / crossAxisCount) / buttonHeight,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: buttons.map((text) {
        return SizedBox(
          height: buttonHeight, // Enforce a specific height
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  backgroundColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(text, textAlign: TextAlign.center),
          ),
        );
      }).toList(),
    );
  }
}
