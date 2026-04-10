import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class SessionReviewsScreen extends StatefulWidget {
  const SessionReviewsScreen({super.key});

  @override
  State<SessionReviewsScreen> createState() => _SessionReviewsScreenState();
}

class _SessionReviewsScreenState extends State<SessionReviewsScreen> {
  bool _isLoading = false;
  List<dynamic> _sessionReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchSessionReviews();
  }

  // 1. Fetching the Session Data from your Node.js backend
  Future<void> _fetchSessionReviews() async {
    setState(() => _isLoading = true);

    try {
      // Keeping the endpoint the same so the backend doesn't break
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/ai-logs'));

      if (response.statusCode == 200) {
        setState(() {
          _sessionReviews = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching session reviews: $e");
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

  // 3. Dynamic Modal to Inspect the Session Output
  void _inspectSession(Map<String, dynamic> session) {
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
                          "Session Analysis Details",
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
                            _buildDetailSection("Session ID", session['_id'] ?? 'Unknown', modalTheme),
                            _buildDetailSection("User ID", session['userId'] ?? 'Unknown', modalTheme),
                            const SizedBox(height: 16),
                            _buildDetailSection("Raw Transcription", session['transcription'] ?? 'No transcription available.', modalTheme, isCode: true),
                            const SizedBox(height: 16),
                            _buildDetailSection("AI Feedback Summary", session['aiFeedback'] ?? 'AI is still processing or failed to generate feedback.', modalTheme),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _scoreBadge("Pace", session['paceScore']?.toString() ?? '0', Colors.blue),
                                _scoreBadge("Clarity", session['clarityScore']?.toString() ?? '0', Colors.green),
                                _scoreBadge("Energy", session['energyScore']?.toString() ?? '0', Colors.orange),
                                _scoreBadge("Overall", session['overallScore']?.toString() ?? '0', AppTheme.primaryColor),
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

  Widget _buildDetailSection(String title, String content, dynamic theme, {bool isCode = false}) {
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
              "Session Reviews",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.headingColor),
            ),
            ElevatedButton.icon(
              onPressed: _fetchSessionReviews,
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text("Refresh Reviews", style: TextStyle(color: Colors.white)),
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
                : _sessionReviews.isEmpty
                    ? Center(child: Text("No session reviews found.", style: TextStyle(color: theme.subtleTextColor)))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            // ---> THE VERTICAL SCROLL FIX <---
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
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
                                      rows: _sessionReviews.map((session) {
                                        String status = session['status'] ?? 'Pending';
                                        Color statusColor = status == 'Completed' ? Colors.green 
                                                          : status == 'Failed' ? Colors.red 
                                                          : Colors.orange;

                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((states) => isDark ? AppTheme.darkSurface : theme.cardColor),
                                          cells: [
                                            DataCell(Text(_formatDate(session['createdAt']), style: TextStyle(color: theme.subtleTextColor))),
                                            DataCell(Text(session['_id'].toString().substring(0, 8) + '...', style: TextStyle(fontFamily: 'monospace', color: theme.bodyTextColor))),
                                            DataCell(Text('${session['durationSeconds'] ?? 0} sec', style: TextStyle(color: theme.bodyTextColor))),
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
                                              '${session['overallScore'] ?? '-'}',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.bodyTextColor),
                                            )),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.troubleshoot, color: Colors.blue, size: 20),
                                                tooltip: 'Inspect Session',
                                                onPressed: () => _inspectSession(session),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
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