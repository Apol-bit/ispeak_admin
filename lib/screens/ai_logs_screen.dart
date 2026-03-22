import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class AILogsScreen extends StatefulWidget {
  const AILogsScreen({super.key});

  @override
  State<AILogsScreen> createState() => _AILogsScreenState();
}

class _AILogsScreenState extends State<AILogsScreen> {
  bool _isLoading = false;
  List<dynamic> _aiLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAILogs();
  }

  // 1. Fetching the AI Processing Logs from your Node.js backend
  Future<void> _fetchAILogs() async {
    setState(() => _isLoading = true);
    try {
      // Assuming you have an endpoint that returns detailed session/AI logs
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/ai-logs'));
      if (response.statusCode == 200) {
        setState(() {
          _aiLogs = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching AI logs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Formatting the Date
  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return "Invalid Date";
    }
  }

  // 3. Dynamic Modal to Inspect the Raw AI Output
  void _inspectAILog(Map<String, dynamic> log) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) => ThemeProvider(
        isDarkMode: isDark,
        child: Builder(
          builder: (themeContext) {
            final modalTheme = ThemeProvider.of(themeContext)!;
            return Dialog(
              backgroundColor: modalTheme.scaffoldColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 600,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "AI Analysis Details",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: modalTheme.headingColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: modalTheme.headingColor),
                          onPressed: () => Navigator.pop(themeContext),
                        ),
                      ],
                    ),
                    Divider(color: modalTheme.borderColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLogSection("Session ID", log['_id'] ?? 'Unknown', modalTheme),
                            _buildLogSection("User ID", log['userId'] ?? 'Unknown', modalTheme),
                            const SizedBox(height: 16),
                            _buildLogSection("Raw Transcription", log['transcription'] ?? 'No transcription available.', modalTheme, isCode: true),
                            const SizedBox(height: 16),
                            _buildLogSection("AI Feedback Summary", log['aiFeedback'] ?? 'AI is still processing or failed to generate feedback.', modalTheme),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _scoreBadge("WPM", log['wpmScore']?.toString() ?? '0', Colors.blue),
                                _scoreBadge("Clarity", log['clarityScore']?.toString() ?? '0', Colors.green),
                                _scoreBadge("Energy", log['energyScore']?.toString() ?? '0', Colors.orange),
                                _scoreBadge("Overall", log['overallScore']?.toString() ?? '0', AppTheme.primaryColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogSection(String title, String content, dynamic theme, {bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.headingColor, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.borderColor),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: theme.bodyTextColor,
              fontFamily: isCode ? 'monospace' : null,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreBadge(String label, String score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(score, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "AI Processing Logs",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.headingColor),
            ),
            ElevatedButton.icon(
              onPressed: _fetchAILogs,
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text("Refresh Logs", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _aiLogs.isEmpty
                    ? Center(child: Text("No AI logs found.", style: TextStyle(color: theme.subtleTextColor)))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(theme.scaffoldColor),
                                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.headingColor),
                                    columnSpacing: 24.0,
                                    horizontalMargin: 24.0,
                                    dataRowMaxHeight: 60,
                                    columns: const [
                                      DataColumn(label: Text('Timestamp')),
                                      DataColumn(label: Text('Session ID')),
                                      DataColumn(label: Text('Audio Length')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Overall Score')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: _aiLogs.map((log) {
                                      String status = log['status'] ?? 'Pending';
                                      Color statusColor = status == 'Completed' ? Colors.green 
                                                        : status == 'Failed' ? Colors.red 
                                                        : Colors.orange;

                                      return DataRow(
                                        color: WidgetStateProperty.resolveWith<Color?>((states) => isDark ? AppTheme.darkSurface : theme.cardColor),
                                        cells: [
                                          DataCell(Text(_formatDate(log['createdAt']), style: TextStyle(color: theme.subtleTextColor))),
                                          DataCell(Text(log['_id'].toString().substring(0, 8) + '...', style: TextStyle(fontFamily: 'monospace', color: theme.bodyTextColor))),
                                          DataCell(Text('${log['durationSeconds'] ?? 0} sec', style: TextStyle(color: theme.bodyTextColor))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(
                                            '${log['overallScore'] ?? '-'}',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.bodyTextColor),
                                          )),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.troubleshoot, color: Colors.blue, size: 20),
                                              tooltip: 'Inspect AI Output',
                                              onPressed: () => _inspectAILog(log),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}