import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import 'create_resource_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late Future<List<dynamic>> _resourcesFuture;

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  void _fetchResources() {
    setState(() {
      _resourcesFuture = http
          .get(Uri.parse('${ApiConfig.baseUrl}/resources'))
          .then((response) {
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to load resources');
        }
      });
    });
  }

  Future<void> _deleteResource(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: const Text('Are you sure you want to delete this permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/resources/$id'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource deleted!'), backgroundColor: Colors.green),
        );
        _fetchResources();
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Manage Resources",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.headingColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final isDark = ThemeProvider.of(context)!.isDarkMode;
                showDialog(
                  context: context,
                  builder: (dialogContext) => ThemeProvider(
                    isDarkMode: isDark,
                    child: Builder(
                      builder: (themeContext) {
                        final theme = ThemeProvider.of(themeContext)!;
                        return Dialog(
                          backgroundColor: theme.scaffoldColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: 700,
                            height: MediaQuery.of(context).size.height * 0.85,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.close, color: theme.headingColor),
                                  onPressed: () => Navigator.pop(themeContext),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: CreateResourceScreen(), // Create Mode
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ).then((_) => _fetchResources());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add New", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            child: FutureBuilder<List<dynamic>>(
              future: _resourcesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.bodyTextColor)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No resources found. Click 'Add New' to start!", style: TextStyle(color: theme.subtleTextColor)));
                }

                final resources = snapshot.data!;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 250, 
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent, 
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(theme.scaffoldColor),
                          columnSpacing: 40,
                          horizontalMargin: 24,
                          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.headingColor),
                          dataTextStyle: TextStyle(color: theme.bodyTextColor),
                          columns: const [
                            DataColumn(label: Expanded(child: Text('Type'))),
                            DataColumn(label: Expanded(child: Text('Title'))),
                            DataColumn(label: Expanded(child: Text('Difficulty'))),
                            DataColumn(label: Expanded(child: Text('Language'))),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: resources.map((item) {
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((states) => theme.cardColor),
                              cells: [
                                DataCell(Chip(
                                  label: Text(item['type'] ?? 'N/A', style: const TextStyle(fontSize: 12)), 
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  side: BorderSide.none,
                                )),
                                DataCell(Text(item['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(item['difficulty'] ?? 'N/A')),
                                DataCell(Text(item['language'] ?? 'N/A')),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        // UPDATE MODE LOGIC: Opens modal with existing data!
                                        final isDark = ThemeProvider.of(context)!.isDarkMode;
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => ThemeProvider(
                                            isDarkMode: isDark,
                                            child: Builder(
                                              builder: (themeContext) {
                                                final theme = ThemeProvider.of(themeContext)!;
                                                return Dialog(
                                                  backgroundColor: theme.scaffoldColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Container(
                                                    width: 700,
                                                    height: MediaQuery.of(context).size.height * 0.85,
                                                    padding: const EdgeInsets.all(16),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(Icons.close, color: theme.headingColor),
                                                          onPressed: () => Navigator.pop(themeContext),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                            child: CreateResourceScreen(resource: item), // Pass data here!
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ).then((_) => _fetchResources());
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _deleteResource(item['_id']),
                                    ),
                                  ],
                                )),
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