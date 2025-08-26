import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ImportFileCard extends StatefulWidget {
  const ImportFileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<ImportFileCard> createState() => _ImportFileCardState();
}

class _ImportFileCardState extends State<ImportFileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 31),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FlowyText(
                    widget.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImportServiceCard extends StatefulWidget {
  const ImportServiceCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<ImportServiceCard> createState() => _ImportServiceCardState();
}

class _ImportServiceCardState extends State<ImportServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 21),
            child: Row(
              children: [
                // Service icon - fallback to text for now
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FlowyText(
                      widget.title[0].toUpperCase(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlowyText(
                        widget.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 4),
                      FlowyText(
                        widget.subtitle,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
