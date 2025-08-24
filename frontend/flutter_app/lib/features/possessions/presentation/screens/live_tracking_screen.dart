// lib/features/possessions/presentation/screens/live_tracking_screen.dart

import 'package:flutter/material.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  List<String> _sequence = [];

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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _Panel(
                      title: 'OFFENCE',
                      child: _OffensePanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'OFFENCE HALF COURT',
                      child: _HalfCourtPanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'DEFFENCE',
                      child: _DefensePanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'PLAYERS',
                      child: _PlayersPanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'CONTROL',
                      child: _ControlPanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'OUTCOME',
                      child: _OutcomePanel(onButtonPressed: _onButtonPressed),
                    ),
                    _Panel(
                      title: 'ADVANCE',
                      child: _AdvancePanel(onButtonPressed: _onButtonPressed),
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

  const _ActionButton({
    required this.text,
    this.color,
    this.textColor,
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

// --- CUSTOM WIDGETS FOR EACH PANEL (REBUILT FOR SAFETY) ---

class _OffensePanel extends StatelessWidget {
  final ValueChanged<String> onButtonPressed;
  const _OffensePanel({required this.onButtonPressed});
  @override
  Widget build(BuildContext context) {
    // Using Wrap internally is safer than nested Rows
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          [
                'FastBreak',
                'Transit',
                '<14s',
                'BoB 1',
                'BoB 2',
                'SoB 1',
                'SoB 2',
                'Special',
                'Special',
                'ATO Spec',
                'Set 13',
                'Set 14',
              ]
              .map(
                (t) => _ActionButton(
                  text: t,
                  color: Colors.green,
                  onPressed: onButtonPressed,
                ),
              )
              .toList(),
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
            _ActionButton(text: 'PnR', onPressed: onButtonPressed),
            _ActionButton(text: 'Att. CloseOut', onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Score', onPressed: onButtonPressed),
            _ActionButton(text: 'Aft. Kick Out', onPressed: onButtonPressed),
          ],
        ),
        TableRow(
          children: [
            _ActionButton(text: 'Big Guy', onPressed: onButtonPressed),
            _ActionButton(text: 'Aft. Ext Pass', onPressed: onButtonPressed),
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
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          [
                'SWITCH',
                'DROP',
                'HEDGE',
                'TRAP',
                'ICE',
                'FLAT',
                '/',
                '2-3',
                '3-2',
                '1-3-1',
                'Zone Press',
                'ISO',
              ]
              .map(
                (t) => _ActionButton(
                  text: t,
                  color: Colors.red[700],
                  onPressed: onButtonPressed,
                ),
              )
              .toList(),
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
          crossAxisCount: 12, // 5 players per team
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            24,
            (i) => _ActionButton(
              text: '#',
              color: i < 12 ? Colors.blue[800] : Colors.grey[800],
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
