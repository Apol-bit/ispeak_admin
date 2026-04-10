import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isLoading = false;
  
  // --- NEW: Split the lists and add a toggle state ---
  List<dynamic> _activeUsers = [];
  List<dynamic> _archivedUsers = [];
  bool _showingArchived = false; 

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  String _getInitials(String fName, String lName, String uName) {
    if (fName.isNotEmpty && lName.isNotEmpty) {
      return '${fName[0]}${lName[0]}'.toUpperCase();
    }
    if (uName.isNotEmpty && uName != 'Unknown') {
      return uName[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // --- NEW: Save both lists into state ---
          _activeUsers = data['activeUsers'] ?? []; 
          _archivedUsers = data['archivedUsers'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveUser(String id, String name) async {
    bool confirm = await _showConfirmDialog(
      "Archive $name?",
      "This will revoke their access to the app, but keep their speech data safe for your analytics.",
      "Archive User",
      Colors.orange,
    );

    if (confirm) {
      try {
        final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/users/$id/archive'));
        if (response.statusCode == 200) {
          _fetchUsers(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User safely archived"))
          );
        }
      } catch (e) {
        debugPrint("Error archiving user: $e");
      }
    }
  }

  // The Unarchive Function
  Future<void> _unarchiveUser(String id, String name) async {
    bool confirm = await _showConfirmDialog(
      "Restore $name?",
      "This will reactivate their account and allow them to log in again.",
      "Restore User",
      Colors.green,
    );

    if (confirm) {
      try {
        final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/users/$id/unarchive'));
        if (response.statusCode == 200) {
          _fetchUsers(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User successfully restored!"))
          );
        }
      } catch (e) {
        debugPrint("Error restoring user: $e");
      }
    }
  }

  Future<void> _toggleUserStatus(String userId) async {
    try {
      final response = await http.patch(Uri.parse('${ApiConfig.baseUrl}/users/$userId/status'));
      if (response.statusCode == 200) {
        _fetchUsers(); // Refresh to ensure sync
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account status updated"), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  Future<bool> _showConfirmDialog(String title, String content, String confirmText, Color confirmColor) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmText, style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    // Decide which list to show based on the toggle
    final displayList = _showingArchived ? _archivedUsers : _activeUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showingArchived ? "Archived Users" : "Manage Users",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.headingColor,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showingArchived = !_showingArchived;
                    });
                  },
                  icon: Icon(
                    _showingArchived ? Icons.people : Icons.archive, 
                    color: _showingArchived ? AppTheme.primaryColor : Colors.orange,
                    size: 18,
                  ),
                  label: Text(
                    _showingArchived ? "View Active Users" : "View Archive",
                    style: TextStyle(
                      color: _showingArchived ? AppTheme.primaryColor : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _fetchUsers,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
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
                : displayList.isEmpty
                    ? Center(
                        child: Text(
                          _showingArchived ? "No archived users found." : "No active users found.",
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
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(theme.scaffoldColor),
                                      headingTextStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.headingColor,
                                      ),
                                      columnSpacing: 32.0,
                                      horizontalMargin: 24.0,
                                      dataRowMaxHeight: 70.0,
                                      columns: const [
                                        DataColumn(label: Expanded(child: Text('User Profile'))),
                                        DataColumn(label: Expanded(child: Text('Email Address'))),
                                        DataColumn(label: Text('Date Joined')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Access')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: displayList.map((user) {
                                        String fName = user['firstName'] ?? '';
                                        String lName = user['lastName'] ?? '';
                                        String uName = user['username'] ?? 'Unknown';

                                        String fullName = (fName.isEmpty && lName.isEmpty)
                                            ? uName
                                            : '$fName $lName'.trim();

                                        String initials = _getInitials(fName, lName, uName);
                                        bool isBanned = user['status'] == 'Banned';

                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            return isDark ? AppTheme.darkSurface : theme.cardColor;
                                          }),
                                          cells: [
                                            DataCell(
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18,
                                                    backgroundColor: _showingArchived ? Colors.grey.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                                                    child: Text(
                                                      initials,
                                                      style: TextStyle(
                                                        color: _showingArchived ? Colors.grey : AppTheme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        fullName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.bodyTextColor,
                                                        ),
                                                      ),
                                                      Text(
                                                        '@$uName',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(Text(
                                              user['email'] ?? 'No Email',
                                              style: TextStyle(color: theme.bodyTextColor),
                                            )),
                                            DataCell(Text(
                                              _formatDate(user['createdAt']),
                                              style: TextStyle(color: theme.subtleTextColor),
                                            )),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _showingArchived 
                                                      ? Colors.orange.withOpacity(0.15)
                                                      : isBanned
                                                          ? Colors.red.withOpacity(0.15)
                                                          : Colors.green.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _showingArchived ? 'Archived' : (user['status'] ?? 'Active'),
                                                  style: TextStyle(
                                                    color: _showingArchived
                                                        ? Colors.orange.shade400
                                                        : isBanned
                                                            ? Colors.red.shade400
                                                            : Colors.green.shade400,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Switch(
                                                value: !isBanned,
                                                activeColor: Colors.green,
                                                onChanged: _showingArchived ? null : (value) => _toggleUserStatus(user['_id']),
                                              ),
                                            ),
                                            DataCell(
                                              _showingArchived
                                                  ? IconButton(
                                                      icon: const Icon(Icons.unarchive, color: Colors.green, size: 22),
                                                      tooltip: 'Restore User',
                                                      onPressed: () => _unarchiveUser(user['_id'], uName),
                                                    )
                                                  : IconButton(
                                                      icon: const Icon(Icons.archive_outlined, color: Colors.orange, size: 22),
                                                      tooltip: 'Archive User',
                                                      onPressed: () => _archiveUser(user['_id'], uName),
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