import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/logging/file_logger.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _logContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFile();
  }

  Future<void> _loadLogFile() async {
    try {
      final logFilePath = FileLogger().logFilePath;
      
      // Check if logger is initialized
      if (logFilePath == 'Logger not initialized yet') {
        setState(() {
          _logContent = 'Logger not initialized yet. Please restart the app.';
          _isLoading = false;
        });
        return;
      }
      
      // We're using enhanced console logging
      setState(() {
        _logContent = '''Enhanced Console Logging Active

All logs are being written to the console with timestamps and enhanced formatting.

To view the logs:
1. Open your IDE's console/debug output
2. Look for logs with timestamps and colored output
3. All possession data, API responses, and errors will be logged there

Logger Status: ${FileLogger().isInitialized ? "Initialized" : "Not Initialized"}
Log Type: $logFilePath

The console will show logs like:
[INFO] === POSSESSION DATA LOG ===
[INFO] Method: createPossession
[INFO] Data: {possession_type: "offensive", ...}
[INFO] ==========================''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logContent = 'Error loading log information: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
         title: const Text('Debug Logs'),
         actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _loadLogFile,
           ),
                       IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: () async {
                await FileLogger().forceReinitialize();
                _loadLogFile();
              },
              tooltip: 'Reinitialize Logger',
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                await FileLogger().testFileWriting();
              },
              tooltip: 'Test File Writing',
            ),
           IconButton(
             icon: const Icon(Icons.copy),
             onPressed: () {
               // Copy log content to clipboard
               // You can implement clipboard functionality here
             },
           ),
         ],
       ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Logger Status: ${FileLogger().isInitialized ? "Initialized" : "Not Initialized"}',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                           color: FileLogger().isInitialized ? Colors.green : Colors.red,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         'Log File: ${FileLogger().logFilePath}',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                           color: FileLogger().logFilePath == 'Logger not initialized yet' 
                             ? Colors.red 
                             : null,
                         ),
                       ),
                     ],
                   ),
                 ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _logContent,
                        style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
