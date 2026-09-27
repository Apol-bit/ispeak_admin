import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'create_resource_screen.dart';
import '../widgets/resource_icon.dart';
import '../widgets/resource_type_filter.dart';
import '../widgets/loading_skeleton.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late Future<List<dynamic>> _resourcesFuture;
  final Map<String, List<String>> _orderOverrides = {};
  final Set<String> _savingGroups = {};

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  void _fetchResources() {
    _orderOverrides.clear();
    setState(() {
      _resourcesFuture =
          ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/resources')).then((
            response,
          ) {
            if (response.statusCode == 200) {
              return json.decode(response.body);
            } else {
              throw Exception('Failed to load resources');
            }
          });
    });
  }

  Future<void> _deleteResource(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Resource?'),
            content: const Text(
              'Are you sure you want to delete this permanently?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
    if (!confirm) return;

    try {
      final response = await ApiClient.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/resources/$id'),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource deleted!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchResources();
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _type = 'All';
  String _search = '';
  static const _types = ['Challenge', 'GuidedTask', 'Script'];
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced', 'None'];

  String _label(String type) => type == 'GuidedTask' ? 'Guided Task' : type;
  Color _categoryColor(String type) =>
      ThemeProvider.of(context)!.categoryColor(type);

  String _groupKey(String type, String difficulty) =>
      type == 'GuidedTask' ? type : '$type|$difficulty';

  List<Map<String, dynamic>> _orderedGroup(
    Iterable<Map<String, dynamic>> source,
    String key,
  ) {
    final rows = source.toList();
    final original = <String, int>{
      for (var index = 0; index < rows.length; index++)
        rows[index]['_id'].toString(): index,
    };
    final override = _orderOverrides[key];
    if (override != null) {
      final position = <String, int>{
        for (var index = 0; index < override.length; index++)
          override[index]: index,
      };
      rows.sort(
        (a, b) => (position[a['_id'].toString()] ?? rows.length).compareTo(
          position[b['_id'].toString()] ?? rows.length,
        ),
      );
      return rows;
    }
    rows.sort((a, b) {
      final first = a['displayOrder'];
      final second = b['displayOrder'];
      if (first is num && second is num) return first.compareTo(second);
      if (first is num) return 1;
      if (second is num) return -1;
      return original[a['_id'].toString()]!.compareTo(
        original[b['_id'].toString()]!,
      );
    });
    return rows;
  }

  Future<void> _reorderGroup(
    String type,
    String difficulty,
    List<Map<String, dynamic>> current,
    int oldIndex,
    int newIndex,
  ) async {
    if (_search.isNotEmpty) return;
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...current];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final key = _groupKey(type, difficulty);
    final previous = _orderOverrides[key];
    final ids = reordered.map((row) => row['_id'].toString()).toList();
    setState(() {
      _orderOverrides[key] = ids;
      _savingGroups.add(key);
    });
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/resources/reorder'),
        body: jsonEncode({
          'type': type,
          if (type != 'GuidedTask') 'difficulty': difficulty,
          'orderedIds': ids,
        }),
      );
      if (response.statusCode != 200) {
        throw StateError('Unable to save resource order');
      }
      if (!mounted) return;
      setState(() => _savingGroups.remove(key));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (previous == null) {
          _orderOverrides.remove(key);
        } else {
          _orderOverrides[key] = previous;
        }
        _savingGroups.remove(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the new order. The previous order was restored.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? resource]) async {
    final dark = ThemeProvider.of(context)!.isDarkMode;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ThemeProvider(
        isDarkMode: dark,
        child: Builder(
          builder: (context) {
            final theme = ThemeProvider.of(context)!;
            return Dialog(
              backgroundColor: theme.scaffoldColor,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.sizeOf(context).height * .85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Close resource editor',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      Expanded(child: CreateResourceScreen(resource: resource)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted && saved == true) _fetchResources();
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _resourceCard(
    Map<String, dynamic> resource,
    ThemeProvider theme, {
    required int order,
    required int dragIndex,
    required bool canReorder,
  }) {
    final type = resource['type'] as String;
    final actions = Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          key: ValueKey('edit-${resource['_id']}'),
          onPressed: () => _openEditor(resource),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
          style: TextButton.styleFrom(foregroundColor: theme.actionColor),
        ),
        TextButton.icon(
          key: ValueKey('delete-${resource['_id']}'),
          onPressed: () => _deleteResource(resource['_id']),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: theme.destructiveColor),
        ),
      ],
    );
    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canReorder) ...[
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: ReorderableDragStartListener(
              key: ValueKey('drag-${resource['_id']}'),
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(Icons.drag_indicator, color: theme.subtleTextColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          key: ValueKey('order-${resource['_id']}'),
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.filterBlue.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '#$order',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.filterBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _categoryColor(type).withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            ResourceIcon.resolve(resource['iconName']),
            color: _categoryColor(type),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource['title'] ?? 'Untitled resource',
                style: TextStyle(
                  color: theme.bodyTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _badge(_label(type), _categoryColor(type)),
                  _badge(resource['language'] ?? 'None', theme.subtleTextColor),
                  _badge(
                    type == 'GuidedTask'
                        ? 'All Levels'
                        : (resource['difficulty'] ?? 'None'),
                    theme.subtleTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return Card(
      key: ValueKey('resource-${resource['_id']}'),
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _resourceGroup(
    String type,
    String difficulty,
    List<Map<String, dynamic>> source,
    ThemeProvider theme,
  ) {
    final key = _groupKey(type, difficulty);
    final rows = _orderedGroup(source, key);
    final canReorder = _search.isEmpty && !_savingGroups.contains(key);
    final label = type == 'GuidedTask' ? 'All Levels' : difficulty;
    final cards = [
      for (var index = 0; index < rows.length; index++)
        _resourceCard(
          rows[index],
          theme,
          order: index + 1,
          dragIndex: index,
          canReorder: canReorder,
        ),
    ];
    return Column(
      key: ValueKey('group-$key'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label — ${rows.length} ${rows.length == 1 ? 'resource' : 'resources'}',
                  style: TextStyle(
                    color: theme.bodyTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_savingGroups.contains(key))
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (canReorder)
          ReorderableListView(
            key: ValueKey('reorder-$key'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) =>
                _reorderGroup(type, difficulty, rows, oldIndex, newIndex),
            children: cards,
          )
        else
          ...cards,
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Text(
              'Manage Resources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.headingColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add Resource'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in ['All', ..._types])
              ResourceTypeFilter(
                key: ValueKey('filter-$type'),
                label: _label(type),
                selected: _type == type,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('resource-search'),
          style: TextStyle(color: theme.bodyTextColor),
          decoration: InputDecoration(
            hintText: 'Search resources...',
            hintStyle: TextStyle(color: theme.subtleTextColor),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) =>
              setState(() => _search = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _resourcesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  !snapshot.hasData) {
                return const SingleChildScrollView(
                  child: SkeletonList(grouped: true),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unable to load resources.',
                        style: TextStyle(color: theme.bodyTextColor),
                      ),
                      TextButton(
                        onPressed: _fetchResources,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }
              final all = (snapshot.data ?? [])
                  .map((r) => Map<String, dynamic>.from(r as Map))
                  .toList();
              final filtered = all
                  .where(
                    (r) =>
                        (_type == 'All' || r['type'] == _type) &&
                        r['title'].toString().toLowerCase().contains(_search),
                  )
                  .toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    all.isEmpty
                        ? 'No resources yet. Add a resource to get started.'
                        : 'No resources found. Try another type or search.',
                    style: TextStyle(color: theme.bodyTextColor),
                  ),
                );
              }
              return ListView(
                children: [
                  if (_search.isNotEmpty)
                    Container(
                      key: const ValueKey('reorder-disabled-message'),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.filterBlue.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Clear search to reorder resources.',
                        style: TextStyle(color: theme.bodyTextColor),
                      ),
                    ),
                  for (final type in _types)
                    if (filtered.any((r) => r['type'] == type)) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _badge(_label(type), _categoryColor(type)),
                            Text(
                              '${filtered.where((r) => r['type'] == type).length} resources',
                              key: ValueKey('count-$type'),
                              style: TextStyle(color: theme.subtleTextColor),
                            ),
                          ],
                        ),
                      ),
                      if (type == 'GuidedTask')
                        _resourceGroup(
                          type,
                          'All Levels',
                          filtered.where((row) => row['type'] == type).toList(),
                          theme,
                        )
                      else
                        for (final difficulty in _difficulties)
                          if (filtered.any(
                            (row) =>
                                row['type'] == type &&
                                (row['difficulty'] ?? 'None') == difficulty,
                          ))
                            _resourceGroup(
                              type,
                              difficulty,
                              filtered
                                  .where(
                                    (row) =>
                                        row['type'] == type &&
                                        (row['difficulty'] ?? 'None') ==
                                            difficulty,
                                  )
                                  .toList(),
                              theme,
                            ),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
