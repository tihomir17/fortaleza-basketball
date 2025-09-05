// lib/features/scouting/presentation/screens/individual_game_prep_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/main.dart';

class IndividualGamePrepScreen extends StatefulWidget {
  const IndividualGamePrepScreen({super.key});

  @override
  State<IndividualGamePrepScreen> createState() => _IndividualGamePrepScreenState();
}

class _IndividualGamePrepScreenState extends State<IndividualGamePrepScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        setState(() {
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      // Mock data for individual game preparation reports
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _reports = [
          {
            'id': 1,
            'title': 'Game Prep - Team Alpha Analysis',
            'report_type': 'UPLOADED_PDF',
            'file_size_mb': 3.2,
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
            'created_by': 'Coach Smith',
            'game_opponent': 'Team Alpha',
            'game_date': DateTime.now().add(const Duration(days: 2)),
            'description': 'Pre-game analysis and preparation materials for upcoming match against Team Alpha.',
          },
          {
            'id': 2,
            'title': 'Defensive Strategy - Team Beta',
            'report_type': 'YOUTUBE_LINK',
            'youtube_url': 'https://www.youtube.com/watch?v=example2',
            'created_at': DateTime.now().subtract(const Duration(days: 3)),
            'created_by': 'Coach Johnson',
            'game_opponent': 'Team Beta',
            'game_date': DateTime.now().add(const Duration(days: 5)),
            'description': 'Video analysis of Team Beta\'s offensive patterns and defensive strategies.',
          },
          {
            'id': 3,
            'title': 'Key Players Focus - Team Gamma',
            'report_type': 'UPLOADED_PDF',
            'file_size_mb': 2.1,
            'created_at': DateTime.now().subtract(const Duration(days: 4)),
            'created_by': 'Coach Williams',
            'game_opponent': 'Team Gamma',
            'game_date': DateTime.now().add(const Duration(days: 7)),
            'description': 'Detailed analysis of Team Gamma\'s key players and their tendencies.',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load game preparation reports: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadReport() async {
    // Navigate to upload screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadGamePrepReportScreen(),
      ),
    ).then((_) {
      // Refresh the list after upload
      _loadReports();
    });
  }

  Future<void> _deleteReport(int reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this game preparation report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = context.read<AuthCubit>().state.token;
        if (token != null) {
          // For now, just remove from local list since we're using mock data
          setState(() {
            _reports.removeWhere((report) => report['id'] == reportId);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game preparation report deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete report: $e')),
        );
      }
    }
  }

  Future<void> _downloadReport(Map<String, dynamic> report) async {
    if (report['report_type'] == 'UPLOADED_PDF') {
      // Handle PDF download
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF download functionality would be implemented here')),
      );
    } else if (report['report_type'] == 'YOUTUBE_LINK') {
      // Handle YouTube link
      final url = report['youtube_url'] as String?;
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open YouTube link')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAME PREPARATION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadReport,
            tooltip: 'Upload Game Prep Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_basketball_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No game preparation reports yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload your first game preparation report',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _ReportCard(
                            report: report,
                            onDownload: () => _downloadReport(report),
                            onDelete: () => _deleteReport(report['id']),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadReport,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Report'),
        tooltip: 'Upload game preparation report',
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final reportType = report['report_type'] as String;
    final isPdf = reportType == 'UPLOADED_PDF';
    final isYoutube = reportType == 'YOUTUBE_LINK';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.play_circle_outline,
                  color: isPdf ? Colors.red : Colors.red[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'vs ${report['game_opponent']} - ${_formatGameDate(report['game_date'] as DateTime)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'download') {
                      onDownload();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.download : Icons.play_arrow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(isPdf ? 'Download PDF' : 'Watch Video'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (report['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                report['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'By ${report['created_by']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report['created_at'] as DateTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isPdf) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.description,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${report['file_size_mb']} MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatGameDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Placeholder for upload screen
class UploadGamePrepReportScreen extends StatelessWidget {
  const UploadGamePrepReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Game Preparation Report'),
      ),
      body: const Center(
        child: Text('Upload game preparation report functionality would be implemented here'),
      ),
    );
  }
}
