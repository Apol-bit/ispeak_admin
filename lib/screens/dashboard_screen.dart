import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingStats = false;
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
    await Future.wait([
      _fetchGlobalStats(),
      _fetchRecentSessions(),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dashboard data updated"), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _fetchGlobalStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalUsers = data['totalUsers'] ?? 0;
          _totalSessions = data['totalSessions'] ?? 0;
          _avgAppScore = data['avgAppScore'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin stats: $e");
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchRecentSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/recent-sessions'));
      if (response.statusCode == 200) {
        setState(() {
          _recentSessions = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching recent sessions: $e");
    } finally {
      setState(() => _isLoadingSessions = false);
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
    final theme = ThemeProvider.of(context);
    final isDark = theme?.isDarkMode ?? false;

    if (_isLoadingStats) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _buildStatCard('Total Users', '$_totalUsers', Icons.people, AppTheme.primaryColor, isDark),
                _buildStatCard('Total Sessions', '$_totalSessions', Icons.mic, Colors.green, isDark),
                _buildStatCard('Avg App Score', '$_avgAppScore%', Icons.stars, Colors.orange, isDark),
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
              color: theme?.headingColor ?? AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme?.cardColor ?? Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme?.borderColor ?? Colors.grey.shade200),
              ),
              child: _isLoadingSessions
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _recentSessions.isEmpty
                      ? Center(
                          child: Text("No sessions recorded yet.",
                              style: TextStyle(color: theme?.subtleTextColor ?? Colors.grey)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 32.0,
                                    headingTextStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme?.tableHeadColor ?? Colors.black87,
                                    ),
                                    dataRowMaxHeight: 60,
                                    columns: const [
                                      DataColumn(label: Text('Date & Time')),
                                      DataColumn(label: Text('Session ID')),
                                      DataColumn(label: Text('WPM')),
                                      DataColumn(label: Text('Clarity')),
                                      DataColumn(label: Text('Energy')),
                                      DataColumn(label: Text('Overall')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: _recentSessions.map((session) {
                                      int overall = (session['overallScore'] ?? 0).toInt();
                                      bool isPending = overall == 0;

                                      return DataRow(
                                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                                          return isDark ? AppTheme.darkSurface : null;
                                        }),
                                        cells: [
                                          DataCell(Text(_formatDate(session['createdAt']),
                                              style: TextStyle(color: theme?.subtleTextColor ?? Colors.grey.shade700))),
                                          DataCell(Text(
                                            session['_id'].toString().substring(0, 8) + '...',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              color: theme?.bodyTextColor ?? Colors.black87,
                                            ),
                                          )),
                                          DataCell(Text('${session['wpmScore'] ?? 0}',
                                              style: TextStyle(color: theme?.bodyTextColor ?? Colors.black87))),
                                          DataCell(Text('${session['fillerWordCount'] ?? 0}',
                                              style: TextStyle(color: theme?.bodyTextColor ?? Colors.black87))),
                                          DataCell(Text('${session['energyScore'] ?? 0}',
                                              style: TextStyle(color: theme?.bodyTextColor ?? Colors.black87))),
                                          DataCell(Text(
                                            '$overall',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isPending
                                                  ? (theme?.subtleTextColor ?? Colors.grey)
                                                  : AppTheme.primaryColor,
                                            ),
                                          )),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isPending
                                                    ? Colors.orange.withOpacity(0.15)
                                                    : Colors.green.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isPending ? 'Pending AI' : 'Processed',
                                                style: TextStyle(
                                                  color: isPending ? Colors.orange.shade400 : Colors.green.shade400,
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
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Refresh Dashboard',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}