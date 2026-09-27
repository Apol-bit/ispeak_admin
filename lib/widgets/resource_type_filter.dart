import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Filter state is independent of the resource category badge palette.
class ResourceTypeFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ResourceTypeFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      backgroundColor: theme.cardColor,
      selectedColor: AppTheme.filterBlue,
      surfaceTintColor: Colors.transparent,
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppTheme.filterBlue
            : theme.cardColor,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : theme.filterTextColor,
      ),
      side: BorderSide(
        color: selected ? AppTheme.filterBlue : theme.filterBorderColor,
      ),
    );
  }
}
