import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/game_repository.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

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
    // Refresh reports when screen becomes visible
    _loadReports();
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
      setState(() {
        _reports = reports;
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
    try {
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

      // Store current context to avoid deactivated widget issues
      final currentContext = context;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
      );

      // Download the report
      final pdfBytes = await sl<GameRepository>().downloadScoutingReport(
        token: token,
        reportId: report['id'],
      );

      // Close loading dialog
      if (mounted && Navigator.of(currentContext).canPop()) {
        Navigator.of(currentContext).pop();
      }

      // Save to device
      if (mounted) {
        await _savePDFToDevice(pdfBytes, report['title']);
      }

    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
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
        await _downloadPDFOnWeb(pdfBytes, title);
      } else {
        await _savePDFToFileSystem(pdfBytes, title);
      }
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  Future<void> _downloadPDFOnWeb(Uint8List pdfBytes, String title) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '')}_$timestamp.pdf';
      
      // Create a data URL for the PDF
      final base64Data = base64Encode(pdfBytes);
      final dataUrl = 'data:application/pdf;base64,$base64Data';
      
      // Store the current context to avoid deactivated widget issues
      final currentContext = context;
      
      // Show dialog with download options
      if (!mounted) return;
      
      final result = await showDialog<String>(
        context: currentContext,
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
              onPressed: () => Navigator.of(dialogContext).pop('copy'),
              child: const Text('Copy Data URL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('open'),
              child: const Text('Open in New Tab'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('cancel'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      // Handle the dialog result
      if (!mounted) return;
      
      switch (result) {
        case 'copy':
          await Clipboard.setData(ClipboardData(text: dataUrl));
          if (mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text('PDF data URL copied to clipboard')),
            );
          }
          break;
        case 'open':
          await Clipboard.setData(ClipboardData(text: dataUrl));
          if (mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text('PDF data URL copied. Paste in new tab to view/download'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          break;
        case 'cancel':
        default:
          // User cancelled, do nothing
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare PDF download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePDFToFileSystem(Uint8List pdfBytes, String title) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting Reports'),
        actions: [
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
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDownload;

  const _ReportCard({
    required this.report,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(report['created_at']);
    final fileSize = report['file_size_mb']?.toString() ?? 'Unknown';
    final isCorrupted = fileSize == '0.0' || fileSize == '0' || fileSize == 'Unknown';

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
                IconButton(
                  icon: Icon(
                    isCorrupted ? Icons.error : Icons.download,
                    color: isCorrupted ? Colors.red : null,
                  ),
                  onPressed: isCorrupted ? null : onDownload,
                  tooltip: isCorrupted ? 'Report is corrupted' : 'Download Report',
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
