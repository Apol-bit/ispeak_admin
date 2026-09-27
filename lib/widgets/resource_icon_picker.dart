import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'resource_icon.dart';

class ResourceIconPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ResourceIconPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final supported = ResourceIcon.supports(value);
    final label = value.trim().isEmpty
        ? ResourceIcon.fallbackName
        : value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon', style: TextStyle(color: theme.subtleTextColor)),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('resource-icon-name'),
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final dark = theme.isDarkMode;
            final selected = await showDialog<String>(
              context: context,
              builder: (_) => ThemeProvider(
                isDarkMode: dark,
                child: _IconPickerDialog(initialValue: value),
              ),
            );
            if (selected != null) onChanged(selected);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.scaffoldColor,
              border: Border.all(color: theme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(ResourceIcon.resolve(value), color: theme.actionColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.bodyTextColor),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.subtleTextColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          supported
              ? 'Selected Material icon'
              : 'Unsupported icon — using default resource icon.',
          key: const ValueKey('resource-icon-status'),
          style: TextStyle(
            color: supported ? theme.subtleTextColor : theme.destructiveColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _IconPickerDialog extends StatefulWidget {
  final String initialValue;
  const _IconPickerDialog({required this.initialValue});

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  String _query = '';
  String _category = 'All';
  late String _selected = ResourceIcon.supports(widget.initialValue)
      ? widget.initialValue.trim()
      : ResourceIcon.fallbackName;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final options = ResourceIcon.filtered(_category, _query);
    return Dialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Icon',
                style: TextStyle(
                  color: theme.headingColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('icon-search'),
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(color: theme.bodyTextColor),
                decoration: InputDecoration(
                  hintText: 'Search icons...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.scaffoldColor,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in ResourceIcon.categories) ...[
                      ChoiceChip(
                        key: ValueKey('icon-category-$category'),
                        label: Text(category),
                        selected: _category == category,
                        selectedColor: AppTheme.filterBlue,
                        backgroundColor: theme.scaffoldColor,
                        side: BorderSide(
                          color: _category == category
                              ? AppTheme.filterBlue
                              : theme.borderColor,
                        ),
                        labelStyle: TextStyle(
                          color: _category == category
                              ? Colors.white
                              : theme.bodyTextColor,
                        ),
                        onSelected: (_) => setState(() => _category = category),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 360
                        ? 2
                        : constraints.maxWidth < 520
                        ? 3
                        : 4;
                    if (options.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching icons',
                          style: TextStyle(color: theme.subtleTextColor),
                        ),
                      );
                    }
                    return GridView.builder(
                      key: const ValueKey('icon-grid'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final selected = option.name == _selected;
                        return InkWell(
                          key: ValueKey('icon-option-${option.name}'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selected = option.name),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.filterBlue.withValues(alpha: .12)
                                  : theme.scaffoldColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.filterBlue
                                    : theme.borderColor,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        option.icon,
                                        color: selected
                                            ? AppTheme.filterBlue
                                            : theme.bodyTextColor,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        option.name,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.bodyTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppTheme.filterBlue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      ResourceIcon.resolve(_selected),
                      color: AppTheme.filterBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selected,
                        key: const ValueKey('selected-icon-name'),
                        style: TextStyle(color: theme.bodyTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    key: const ValueKey('select-icon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.filterBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
