import 'package:flutter/material.dart';

class AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Semantics(
      button: true,
      selected: selected,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected
              ? Colors.white.withValues(alpha: .20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            hoverColor: Colors.white.withValues(alpha: .10),
            splashColor: Colors.white.withValues(alpha: .18),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    color: selected ? Colors.white : Colors.transparent,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                  if (expanded) ...[
                    Expanded(
                      // The sidebar is still 72px on the first expansion frame.
                      // Keep label spacing inside the remaining flexible width.
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
