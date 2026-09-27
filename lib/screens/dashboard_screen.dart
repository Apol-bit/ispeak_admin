import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/load_error.dart';
import '../widgets/summary_card.dart';
import '../widgets/session_review_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onUsers;
  final VoidCallback? onReviews;
  const DashboardScreen({super.key, this.onUsers, this.onReviews});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingStats = false;
  bool _hasStats = false;
  String? _statsError;
  String? _sessionsError;
  bool _isLoadingSessions = false;

  int _totalUsers = 0;
  int _totalSessions = 0;
  int _avgAppScore = 0;

  List<dynamic> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchGlobalStats();
    _fetchRecentSessions();
  }

  Future<void> _refreshData() async {
    await Future.wait([_fetchGlobalStats(), _fetchRecentSessions()]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dashboard data updated"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchGlobalStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });
    try {
      final url = '${ApiConfig.baseUrl}/admin/stats';
      final response = await ApiClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _hasStats = true;
          _totalUsers = data['totalUsers'] ?? 0;
          _totalSessions = data['totalSessions'] ?? 0;
          _avgAppScore = data['avgAppScore'] ?? 0;
        });
      } else {
        throw StateError('Request failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statsError = 'Unable to load data. Please try again.');
      }
      debugPrint("Error fetching admin stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchRecentSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _sessionsError = null;
    });

    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/recent-sessions'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _recentSessions = jsonDecode(response.body);
        });
      } else {
        throw StateError('Request failed');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _sessionsError = 'Unable to load data. Please try again.',
        );
      }
      debugPrint("Error fetching recent sessions: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown";

    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Initial loads have no invented counts; refresh keeps known cards.
          if (_isLoadingStats && !_hasStats)
            const SkeletonSummaryCards()
          else if (_statsError != null)
            LoadError(message: _statsError!, onRetry: _fetchGlobalStats)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _buildStatCard(
                    'Total Users',
                    '$_totalUsers',
                    Icons.people,
                    theme.actionColor,
                    isDark,
                    widget.onUsers,
                  ),
                  _buildStatCard(
                    'Total Sessions',
                    '$_totalSessions',
                    Icons.mic,
                    Colors.green,
                    isDark,
                    widget.onReviews,
                  ),
                  _buildStatCard(
                    'Avg App Score',
                    '$_avgAppScore%',
                    Icons.stars,
                    Colors.orange,
                    isDark,
                    widget.onReviews,
                  ),
                ];

                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 16),
                      cards[1],
                      const SizedBox(height: 16),
                      cards[2],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 20),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 20),
                    Expanded(child: cards[2]),
                  ],
                );
              },
            ),

          const SizedBox(height: 40),

          Text(
            "Recent AI Processing Logs",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.headingColor,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: _isLoadingSessions && _recentSessions.isEmpty
                  ? const SingleChildScrollView(
                      child: SkeletonList(table: true, count: 6),
                    )
                  : _sessionsError != null
                  ? LoadError(
                      message: _sessionsError!,
                      onRetry: _fetchRecentSessions,
                    )
                  : _recentSessions.isEmpty
                  ? Center(
                      child: Text(
                        "No sessions recorded yet.",
                        style: TextStyle(color: theme.subtleTextColor),
                      ),
                    )
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
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: DataTable(
                                    showCheckboxColumn: false,
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
                                      DataColumn(
                                        label: Expanded(
                                          child: Text('Date & Time'),
                                        ),
                                      ),
                                      DataColumn(label: Text('Session ID')),
                                      DataColumn(label: Text('WPM')),
                                      DataColumn(label: Text('Clarity')),
                                      DataColumn(label: Text('Energy')),
                                      DataColumn(label: Text('Overall')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: _recentSessions.map((session) {
                                      int overall =
                                          (session['overallScore'] ?? 0)
                                              .toInt();
                                      String sessionStatus =
                                          session['status'] ?? 'Pending';
                                      bool isPending =
                                          sessionStatus == 'Pending';
                                      bool isFailed = sessionStatus == 'Failed';
                                      Color processingColor = isPending
                                          ? Colors.orange
                                          : isFailed
                                          ? Colors.red
                                          : Colors.green;
                                      String processingLabel = isPending
                                          ? 'Pending AI'
                                          : isFailed
                                          ? 'Failed'
                                          : 'Processed';

                                      return DataRow(
                                        key: ValueKey(
                                          'session-${session['_id']}',
                                        ),
                                        mouseCursor: WidgetStateProperty.all(
                                          SystemMouseCursors.click,
                                        ),
                                        onSelectChanged: (_) =>
                                            showSessionReview(
                                              context,
                                              Map<String, dynamic>.from(
                                                session,
                                              ),
                                            ),
                                        color:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return theme.actionColor
                                                    .withValues(alpha: .12);
                                              }
                                              return isDark
                                                  ? AppTheme.darkSurface
                                                  : theme.cardColor;
                                            }),
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
                                              '${session['wpmScore'] ?? 0}',
                                              style: TextStyle(
                                                color: theme.bodyTextColor,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${session['clarityScore'] ?? 0}',
                                              style: TextStyle(
                                                color: theme.bodyTextColor,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${session['energyScore'] ?? 0}',
                                              style: TextStyle(
                                                color: theme.bodyTextColor,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '$overall',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isPending
                                                    ? theme.subtleTextColor
                                                    : theme.actionColor,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: processingColor
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                processingLabel,
                                                style: TextStyle(
                                                  color: processingColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: theme.actionColor,
        tooltip: 'Refresh Dashboard',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback? onTap,
  ) => SummaryCard(
    key: ValueKey('stat-$title'),
    title: title,
    value: value,
    icon: icon,
    color: color,
    isDark: isDark,
    onTap: onTap,
  );
}
