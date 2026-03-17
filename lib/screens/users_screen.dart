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
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // UPDATED: Now grabs initials securely from First and Last Name
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
        setState(() {
          _users = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String id, String name) async {
    bool confirm = await _showConfirmDialog(
      "Delete $name?",
      "This action is permanent and will remove all their speech data.",
    );
    if (confirm) {
      try {
        final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/users/$id'));
        if (response.statusCode == 200) {
          _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted")));
        }
      } catch (e) {
        debugPrint("Error deleting user: $e");
      }
    }
  }

  Future<void> _toggleUserStatus(String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/$userId/status'),
      );
      if (response.statusCode == 200) {
        setState(() {
          final index = _users.indexWhere((u) => u['_id'] == userId);
          if (index != -1) {
            _users[index]['status'] =
                _users[index]['status'] == 'Banned' ? 'Active' : 'Banned';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Account status updated successfully"),
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Confirm Delete",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
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
    final theme = ThemeProvider.of(context);
    final isDark = theme?.isDarkMode ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Manage Users",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme?.headingColor ?? AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Refresh List"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
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
              color: theme?.cardColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme?.borderColor ?? Colors.grey.shade200),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _users.isEmpty
                    ? Center(
                        child: Text("No users found.",
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
                                  dataRowMaxHeight: 60.0, // Expanded slightly to fit the two lines of text
                                  headingTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme?.tableHeadColor ?? Colors.black87,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('User Profile')),
                                    DataColumn(label: Text('Email Address')),
                                    DataColumn(label: Text('Date Joined')),
                                    DataColumn(label: Text('Status Label')),
                                    DataColumn(label: Text('Access Toggle')),
                                    DataColumn(label: Text('Delete')),
                                  ],
                                  rows: _users.map((user) {
                                    // Extract the new fields
                                    String fName = user['firstName'] ?? '';
                                    String lName = user['lastName'] ?? '';
                                    String uName = user['username'] ?? 'Unknown';
                                    
                                    // Safely combine them
                                    String fullName = (fName.isEmpty && lName.isEmpty) 
                                        ? uName 
                                        : '$fName $lName'.trim();
                                        
                                    String initials = _getInitials(fName, lName, uName);
                                    bool isBanned = user['status'] == 'Banned';

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                                        return isDark ? AppTheme.darkSurface : null;
                                      }),
                                      cells: [
                                        // 1. Profile Cell (Now shows Name + Username)
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    AppTheme.primaryColor.withOpacity(0.1),
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryColor,
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
                                                      color: theme?.bodyTextColor ?? Colors.black87,
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
                                        // 2. Email
                                        DataCell(Text(
                                          user['email'] ?? 'No Email',
                                          style: TextStyle(color: theme?.bodyTextColor ?? Colors.black87),
                                        )),
                                        // 3. Date
                                        DataCell(Text(
                                          _formatDate(user['createdAt']),
                                          style: TextStyle(color: theme?.subtleTextColor ?? Colors.grey.shade700),
                                        )),
                                        // 4. Status Badge
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isBanned
                                                  ? Colors.red.withOpacity(0.15)
                                                  : Colors.green.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              user['status'] ?? 'Active',
                                              style: TextStyle(
                                                color: isBanned
                                                    ? Colors.red.shade400
                                                    : Colors.green.shade400,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 5. Toggle Switch
                                        DataCell(
                                          Switch(
                                            value: !isBanned,
                                            activeColor: Colors.green,
                                            onChanged: (value) => _toggleUserStatus(user['_id']),
                                          ),
                                        ),
                                        // 6. Delete
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 22),
                                            tooltip: 'Delete User',
                                            // Pass the username to the delete confirmation pop-up
                                            onPressed: () => _deleteUser(user['_id'], uName), 
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
    );
  }
}