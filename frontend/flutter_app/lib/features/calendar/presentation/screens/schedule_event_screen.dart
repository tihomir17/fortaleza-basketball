// lib/features/calendar/presentation/screens/schedule_event_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import '../../data/repositories/event_repository.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ScheduleEventScreen extends StatefulWidget {
  final DateTime initialDate;
  const ScheduleEventScreen({super.key, required this.initialDate});

  @override
  State<ScheduleEventScreen> createState() => _ScheduleEventScreenState();
}

class _ScheduleEventScreenState extends State<ScheduleEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedTeamIdForPractice;
  List<User> _playersOnSelectedTeam = [];
  final List<int> _selectedAttendeeIds = []; // To hold the selected player IDs

  // To hold the selected player IDs
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  String _selectedEventType = 'PRACTICE_TEAM';
  int? _selectedTeamId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _startTime = TimeOfDay.now();
    _endDate = widget.initialDate;
    _endTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
    
    // Auto-select team for coaches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectTeamForCoach();
    });
  }
  
  void _autoSelectTeamForCoach() {
    final user = context.read<AuthCubit>().state.user;
    final userTeams = context.read<TeamCubit>().state.teams;
    
    // If user is a coach and has teams, auto-select the first team they coach
    if (user?.role == 'COACH' && userTeams.isNotEmpty) {
      // Find the first team where the user is a coach
      final coachTeam = userTeams.firstWhere(
        (team) => team.coaches.any((coach) => coach.id == user!.id),
        orElse: () => userTeams.first, // Fallback to first team if not found
      );
      
      setState(() {
        _selectedTeamId = coachTeam.id;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      /* handle error */
      return;
    }

    try {
      final finalStartTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final finalEndTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Date validation
      if (finalStartTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot schedule an event in the past.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Stop the submission
      }
      await sl<EventRepository>().createEvent(
        token: token,
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: finalStartTime,
        endTime: finalEndTime,
        eventType: _selectedEventType,
        teamId: (_selectedEventType == 'PRACTICE_TEAM' || 
                 _selectedEventType == 'SCOUTING_MEETING' ||
                 _selectedEventType == 'STRENGTH_CONDITIONING' ||
                 _selectedEventType == 'TEAM_MEETING' ||
                 _selectedEventType == 'TEAM_BUILDING')
            ? _selectedTeamId
            : _selectedTeamIdForPractice,
        attendeeIds: _selectedAttendeeIds,
      );

      if (mounted) {
        sl<RefreshSignal>().notify();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule New Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title *'),
              validator: (v) => v!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final user = context.read<AuthCubit>().state.user;
                final isManagement = user?.role == 'STAFF' && user?.staffType == 'MANAGEMENT';
                
                if (isManagement) {
                  // Management can only create specific event types
                  return DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    items: const [
                      DropdownMenuItem(
                        value: 'TRAVEL_BUS',
                        child: Text('Travel (Bus)'),
                      ),
                      DropdownMenuItem(
                        value: 'TRAVEL_PLANE',
                        child: Text('Travel (Plane)'),
                      ),
                      DropdownMenuItem(
                        value: 'TEAM_BUILDING',
                        child: Text('Team Building'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedEventType = v!),
                    decoration: const InputDecoration(labelText: 'Event Type *'),
                  );
                } else {
                  // All other users can create all event types
                  return DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    items: const [
                      DropdownMenuItem(
                        value: 'PRACTICE_TEAM',
                        child: Text('Team Practice'),
                      ),
                      DropdownMenuItem(
                        value: 'PRACTICE_INDIVIDUAL',
                        child: Text('Individual Practice'),
                      ),
                      DropdownMenuItem(
                        value: 'SCOUTING_MEETING',
                        child: Text('Scouting Meeting'),
                      ),
                      DropdownMenuItem(
                        value: 'STRENGTH_CONDITIONING',
                        child: Text('Strength & Conditioning'),
                      ),
                      DropdownMenuItem(
                        value: 'GAME',
                        child: Text('Game'),
                      ),
                      DropdownMenuItem(
                        value: 'TEAM_MEETING',
                        child: Text('Team Meeting'),
                      ),
                      DropdownMenuItem(
                        value: 'TRAVEL_BUS',
                        child: Text('Travel (Bus)'),
                      ),
                      DropdownMenuItem(
                        value: 'TRAVEL_PLANE',
                        child: Text('Travel (Plane)'),
                      ),
                      DropdownMenuItem(
                        value: 'TEAM_BUILDING',
                        child: Text('Team Building'),
                      ),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _selectedEventType = v!),
                    decoration: const InputDecoration(labelText: 'Event Type *'),
                  );
                }
              },
            ),
            if (_selectedEventType == 'PRACTICE_TEAM' || 
                _selectedEventType == 'SCOUTING_MEETING' ||
                _selectedEventType == 'STRENGTH_CONDITIONING' ||
                _selectedEventType == 'TEAM_MEETING' ||
                _selectedEventType == 'TEAM_BUILDING') ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final user = context.read<AuthCubit>().state.user;
                  final isCoach = user?.role == 'COACH';
                  
                  if (isCoach && _selectedTeamId != null) {
                    // For coaches, show the selected team as read-only
                    final selectedTeam = userTeams.firstWhere(
                      (team) => team.id == _selectedTeamId,
                      orElse: () => userTeams.first,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Team: ${selectedTeam.name}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  } else {
                    // For non-coaches or when no team is selected, show dropdown
                    return DropdownButtonFormField<int>(
                      value: _selectedTeamId,
                      hint: const Text('Select a team'),
                      items: userTeams
                          .map(
                            (team) => DropdownMenuItem(
                              value: team.id,
                              child: Text(team.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTeamId = v),
                      decoration: const InputDecoration(labelText: 'Team *'),
                      validator: (v) => v == null ? 'Team is required' : null,
                    );
                  }
                },
              ),
            ],
            if (_selectedEventType == 'PRACTICE_INDIVIDUAL') ...[
              const SizedBox(height: 16),
              // Step 1: Select the team the players belong to
              DropdownButtonFormField<int>(
                value: _selectedTeamIdForPractice,
                hint: const Text('Select Team for Practice'),
                items: userTeams
                    .map(
                      (team) => DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      ),
                    )
                    .toList(),
                onChanged: (teamId) {
                  setState(() {
                    _selectedTeamIdForPractice = teamId;
                    _playersOnSelectedTeam = userTeams
                        .firstWhere((t) => t.id == teamId)
                        .players;
                    // Reset attendees when team changes
                  });
                },
                decoration: const InputDecoration(labelText: 'Team'),
              ),
              const SizedBox(height: 16),
              // Step 2: Multi-select players from that team
              if (_selectedTeamIdForPractice != null)
                MultiSelectDialogField(
                  items: _playersOnSelectedTeam
                      .map((p) => MultiSelectItem(p.id, p.displayName))
                      .toList(),
                  title: const Text("Select Players"),
                  buttonText: const Text("Attendees *"),
                  onConfirm: (values) {},
                  validator: (values) => (values == null || values.isEmpty)
                      ? 'At least one attendee is required'
                      : null,
                ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Start and End Time Pickers
            _buildDateTimePicker(context, isStart: true),
            const SizedBox(height: 16),
            _buildDateTimePicker(context, isStart: false),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context, {required bool isStart}) {
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStart ? 'Start Time' : 'End Time',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat.yMMMd().format(date)),
                onPressed: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (newDate != null) {
                    setState(
                      () => isStart ? _startDate = newDate : _endDate = newDate,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(time.format(context)),
                onPressed: () async {
                  final newTime = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (newTime != null) {
                    setState(
                      () => isStart ? _startTime = newTime : _endTime = newTime,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
