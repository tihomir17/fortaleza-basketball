// lib/features/games/presentation/screens/upload_scouting_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/teams/presentation/cubit/team_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/teams/data/models/team_model.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/data/models/user_model.dart';
import '../../data/repositories/game_repository.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class UploadScoutingReportScreen extends StatefulWidget {
  const UploadScoutingReportScreen({super.key});

  @override
  State<UploadScoutingReportScreen> createState() => _UploadScoutingReportScreenState();
}

class _UploadScoutingReportScreenState extends State<UploadScoutingReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  
  String _selectedReportType = 'UPLOADED_PDF';
  File? _selectedFile;
  PlatformFile? _selectedPlatformFile; // For web file uploads
  List<User> _selectedUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // Use a timeout to prevent the app from getting stuck
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('File picker timed out. Please try again.');
        },
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Since we're using allowedExtensions: ['pdf'], the file should already be a PDF
        // But let's add some debugging and validation
        print('Selected file: ${file.name}');
        print('File path: ${file.path}');
        print('File extension: ${file.extension}');
        
        // Check if it's a PDF file by name or extension
        final fileName = file.name.toLowerCase();
        final fileExtension = file.extension?.toLowerCase() ?? '';
        final isPdf = fileName.endsWith('.pdf') || fileExtension == 'pdf';
        
        if (file.path != null && isPdf) {
          setState(() {
            _selectedFile = File(file.path!);
            _selectedPlatformFile = file; // Store for web uploads
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF file selected: ${file.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (!isPdf) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid PDF file.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not access file path.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle all errors gracefully
      String errorMessage = 'Error selecting file';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'File picker timed out. Please try again.';
      } else if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'File picker not available. Please use YouTube link instead.';
      } else {
        errorMessage = 'Error selecting file: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectUsers() async {
    final userTeams = context.read<TeamCubit>().state.teams;
    if (userTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teams available')),
      );
      return;
    }

    // Get all users from all teams
    List<User> allUsers = [];
    for (var team in userTeams) {
      allUsers.addAll(team.players);
      allUsers.addAll(team.coaches);
    }

    // Remove duplicates
    allUsers = allUsers.toSet().toList();

    final selectedUsers = await showDialog<List<User>>(
      context: context,
      builder: (context) => _UserSelectionDialog(users: allUsers),
    );

    if (selectedUsers != null) {
      setState(() {
        _selectedUsers = selectedUsers;
      });
    }
  }

  Future<void> _uploadReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReportType == 'UPLOADED_PDF' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    // PDF validation is already handled by the file picker with allowedExtensions: ['pdf']

    if (_selectedReportType == 'YOUTUBE_LINK' && _youtubeUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        throw Exception('Authentication required');
      }

      final taggedUserIds = _selectedUsers.map((user) => user.id).toList();

      await sl<GameRepository>().uploadScoutingReport(
        token: token,
        title: _titleController.text,
        reportType: _selectedReportType,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        pdfFile: _selectedFile,
        platformFile: _selectedPlatformFile,
        youtubeUrl: _youtubeUrlController.text.isNotEmpty ? _youtubeUrlController.text : null,
        taggedUserIds: taggedUserIds.isNotEmpty ? taggedUserIds : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scouting report uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Scouting Report'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadReport,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              Text(
                'Report Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'UPLOADED_PDF',
                    child: Text('Upload PDF Document'),
                  ),
                  DropdownMenuItem(
                    value: 'YOUTUBE_LINK',
                    child: Text('YouTube Video Link'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                    _selectedFile = null;
                    _youtubeUrlController.clear();
                  });
                },
              ),
              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // File Upload or YouTube URL
              if (_selectedReportType == 'UPLOADED_PDF') ...[
                Text(
                  'PDF File *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFile != null
                              ? _selectedFile!.path.split('/').last
                              : 'Tap to select PDF file (.pdf only)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_selectedFile == null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Only PDF files are supported',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _youtubeUrlController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL *',
                    border: OutlineInputBorder(),
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a YouTube URL';
                    }
                    if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                      return 'Please enter a valid YouTube URL';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Tagged Users
              Text(
                'Tagged Users (Download Rights)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectUsers,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedUsers.isEmpty
                                ? 'Tap to select users'
                                : '${_selectedUsers.length} user(s) selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      if (_selectedUsers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedUsers.map((user) => Chip(
                            label: Text(user.username),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                              });
                            },
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadReport,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSelectionDialog extends StatefulWidget {
  final List<User> users;

  const _UserSelectionDialog({required this.users});

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  List<User> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Users'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.users.length,
          itemBuilder: (context, index) {
            final user = widget.users[index];
            final isSelected = _selectedUsers.contains(user);
            
            return CheckboxListTile(
              title: Text(user.username),
              subtitle: Text('${user.firstName} ${user.lastName} (${user.role})'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedUsers.add(user);
                  } else {
                    _selectedUsers.remove(user);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedUsers),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
