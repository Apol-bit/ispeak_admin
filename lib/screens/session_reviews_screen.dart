import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/load_error.dart';
import '../widgets/session_review_dialog.dart';

class SessionReviewsScreen extends StatefulWidget {
  const SessionReviewsScreen({super.key});

  @override
  State<SessionReviewsScreen> createState() => _SessionReviewsScreenState();
}

class _SessionReviewsScreenState extends State<SessionReviewsScreen> {
  bool _isLoading = false;
  String? _loadError;
  List<dynamic> _sessionReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchSessionReviews();
  }

  // 1. Fetching the Session Data from your Node.js backend
  Future<void> _fetchSessionReviews() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/ai-logs'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _sessionReviews = jsonDecode(response.body);
        });
      } else {
        throw StateError('Request failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'Unable to load data. Please try again.');
      }
      debugPrint("Error fetching session reviews: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _inspectSession(Map<String, dynamic> session) =>
      showSessionReview(context, session);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text(
              "Session Reviews",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.headingColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _fetchSessionReviews,
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text(
                "Refresh Reviews",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            child: _isLoading && _sessionReviews.isEmpty
                ? const SingleChildScrollView(
                    child: SkeletonList(table: true, count: 6),
                  )
                : _loadError != null
                ? LoadError(message: _loadError!, onRetry: _fetchSessionReviews)
                : _sessionReviews.isEmpty
                ? Center(
                    child: Text(
                      "No session reviews found.",
                      style: TextStyle(color: theme.subtleTextColor),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    theme.scaffoldColor,
                                  ),
                                  headingTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.headingColor,
                                  ),
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
                                    String status =
                                        session['status'] ?? 'Pending';
                                    Color statusColor = status == 'Completed'
                                        ? Colors.green
                                        : status == 'Failed'
                                        ? Colors.red
                                        : Colors.orange;

                                    return DataRow(
                                      color:
                                          WidgetStateProperty.resolveWith<
                                            Color?
                                          >(
                                            (states) => isDark
                                                ? AppTheme.darkSurface
                                                : theme.cardColor,
                                          ),
                                      cells: [
                                        DataCell(
                                          Text(
                                            _formatDate(session['createdAt']),
                                            style: TextStyle(
                                              color: theme.subtleTextColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${session['_id'].toString().substring(0, 8)}...',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              color: theme.bodyTextColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${session['durationSeconds'] ?? 0} sec',
                                            style: TextStyle(
                                              color: theme.bodyTextColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${session['overallScore'] ?? '-'}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.bodyTextColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.troubleshoot,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: 'Inspect Session',
                                            hoverColor: Colors.blue.withValues(
                                              alpha: 0.08,
                                            ),
                                            highlightColor: Colors.blue
                                                .withValues(alpha: 0.15),
                                            splashColor: Colors.blue.withValues(
                                              alpha: 0.12,
                                            ),
                                            onPressed: () =>
                                                _inspectSession(session),
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
