import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/game_repository.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_app/core/services/web_download_service.dart';
import 'upload_scouting_report_screen.dart';

class ScoutingReportsScreen extends StatefulWidget {
  const ScoutingReportsScreen({super.key});

  @override
  State<ScoutingReportsScreen> createState() => _ScoutingReportsScreenState();
}

class _ScoutingReportsScreenState extends State<ScoutingReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load reports if not already loading and reports are empty
    if (!_isLoading && _reports.isEmpty) {
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final reports = await sl<GameRepository>().getScoutingReports(token: token);
      
      // Filter out corrupted reports (only filter out reports with null/undefined file sizes)
      final validReports = reports.where((report) {
        final fileSize = report['file_size_mb'];
        // Only filter out reports with null/undefined file sizes
        // Small files (0.0 MB) are valid and should be shown
        return fileSize != null;
      }).toList();
      
      setState(() {
        _reports = validReports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reports: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport(Map<String, dynamic> report) async {
    // Check if report is corrupted
    final fileSize = report['file_size_mb']?.toString() ?? 'Unknown';
    final isCorrupted = fileSize == '0.0' || fileSize == '0' || fileSize == 'Unknown';
    
    if (isCorrupted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This report is corrupted and cannot be downloaded. Please regenerate it.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
      }
      return;
    }

    // Use unawaited to prevent blocking the UI
    unawaited(_performDownload(report, token));
  }

  Future<void> _performDownload(Map<String, dynamic> report, String token) async {
    try {
      // Download the report without showing loading dialog
      final pdfBytes = await sl<GameRepository>().downloadScoutingReport(
        token: token,
        reportId: report['id'],
      );

      // Save to device (non-blocking)
      if (mounted) {
        unawaited(_savePDFToDevice(pdfBytes, report['title']));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePDFToDevice(Uint8List pdfBytes, String title) async {
    try {
      if (kIsWeb) {
        unawaited(_downloadPDFOnWeb(pdfBytes, title));
      } else {
        unawaited(_savePDFToFileSystem(pdfBytes, title));
      }
    } catch (e) {
      // Don't rethrow - just log the error to prevent UI blocking
    }
  }

  Future<void> _downloadPDFOnWeb(Uint8List pdfBytes, String title) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '')}_$timestamp.pdf';
      
      // Show dialog in a non-blocking way
      unawaited(_showDownloadDialog(pdfBytes, filename));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

         Future<void> _showDownloadDialog(Uint8List pdfBytes, String filename) async {
    if (!mounted) return;
    
    // Show dialog without blocking
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF: $filename'),
            const SizedBox(height: 16),
            const Text('Choose download method:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('download'),
            child: const Text('Download File'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('view'),
            child: const Text('View in New Tab'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('copy'),
            child: const Text('Copy Data URL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    
    // Handle the result immediately without unawaited
    _handleDownloadResult(result, pdfBytes, filename);
  }

  void _handleDownloadResult(String? result, Uint8List pdfBytes, String filename) {
    switch (result) {
      case 'download':
        // Direct download using JavaScript
        WebDownloadService.downloadFile(pdfBytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF download started'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'view':
        // Open in new tab
        WebDownloadService.openFileInNewTab(pdfBytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF opened in new tab'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'copy':
        // Fallback to clipboard method (non-blocking)
        unawaited(_copyToClipboard(pdfBytes));
        break;
      case 'cancel':
      default:
        // User cancelled, do nothing
        break;
    }
  }

  Future<void> _copyToClipboard(Uint8List pdfBytes) async {
    try {
      final base64Data = base64Encode(pdfBytes);
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      await Clipboard.setData(ClipboardData(text: dataUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF data URL copied to clipboard. Paste in new tab to view/download'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy to clipboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePDFToFileSystem(Uint8List pdfBytes, String title) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '')}_$timestamp.pdf';
      final file = File('${directory.path}/$filename');

      // Write PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renameReport(Map<String, dynamic> report) async {
    final currentTitle = report['title'] ?? 'Untitled Report';
    final textController = TextEditingController(text: currentTitle);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Report'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Report Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    
    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      try {
        final token = context.read<AuthCubit>().state.token;
        if (token == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication required')),
            );
          }
          return;
        }
        
        // Call backend to rename the report
        await sl<GameRepository>().renameScoutingReport(
          token: token,
          reportId: report['id'],
          newTitle: newTitle,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report renamed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the reports list
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final reportTitle = report['title'] ?? 'Untitled Report';
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "$reportTitle"? This action cannot be undone.'),
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
        if (token == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication required')),
            );
          }
          return;
        }

        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleting report...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Delete the report
        await sl<GameRepository>().deleteScoutingReport(
          token: token,
          reportId: report['id'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the reports list
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cleanupCorruptedReports() async {
    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleaning up corrupted reports...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Call the cleanup endpoint
      final result = await sl<GameRepository>().cleanupCorruptedReports(token: token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cleanup completed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the reports list
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cleanup reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UploadScoutingReportScreen(),
                ),
              ).then((_) => _loadReports()); // Refresh after upload
            },
            tooltip: 'Upload New Report',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _cleanupCorruptedReports,
            tooltip: 'Cleanup Corrupted Reports',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No scouting reports yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate reports from the Advanced Analytics screen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _ReportCard(
          report: report,
          onDownload: () => _downloadReport(report),
          onRename: _renameReport,
          onDelete: () => _deleteReport(report),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDownload;
  final Function(Map<String, dynamic>) onRename;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  void _openYouTubeLink(String url) {
    // TODO: Implement YouTube link opening
    // For now, just show a snackbar
    // In a real implementation, you might want to use url_launcher package
    print('Opening YouTube link: $url');
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(report['created_at']);
    final fileSize = report['file_size_mb']?.toString() ?? 'Unknown';
    final isCorrupted = fileSize == '0.0' || fileSize == '0' || fileSize == 'Unknown';
    final reportType = report['report_type'] ?? 'GENERATED_PDF';
    final isYouTube = reportType == 'YOUTUBE_LINK';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            report['title'] ?? 'Untitled Report',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCorrupted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'CORRUPTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${createdAt.toString().split('.')[0]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                                 Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: const Icon(Icons.edit),
                       onPressed: () => onRename(report),
                       tooltip: 'Rename Report',
                     ),
                     IconButton(
                       icon: Icon(
                         isCorrupted ? Icons.error : 
                         isYouTube ? Icons.play_arrow : Icons.download,
                         color: isCorrupted ? Colors.red : null,
                       ),
                       onPressed: isCorrupted ? null : 
                         isYouTube ? () => _openYouTubeLink(report['youtube_url']) : onDownload,
                       tooltip: isCorrupted ? 'Report is corrupted' : 
                         isYouTube ? 'Open YouTube Video' : 'Download Report',
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: onDelete,
                       tooltip: 'Delete Report',
                     ),
                   ],
                 ),
              ],
            ),
            if (report['description'] != null && report['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report['description'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.description,
                  label: 'Size',
                  value: '$fileSize MB',
                ),
                const SizedBox(width: 8),
                if (report['team'] != null) ...[
                  _InfoChip(
                    icon: Icons.sports_basketball,
                    label: 'Team',
                    value: report['team']['name'],
                  ),
                  const SizedBox(width: 8),
                ],
                if (report['last_games'] != null) ...[
                  _InfoChip(
                    icon: Icons.games,
                    label: 'Games',
                    value: 'Last ${report['last_games']}',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
