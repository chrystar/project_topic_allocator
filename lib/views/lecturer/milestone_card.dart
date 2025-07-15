import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/milestone.dart';

class MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MilestoneCard({
    super.key,
    required this.milestone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Schedule the state update for after the current frame
          WidgetsBinding.instance.addPostFrameCallback((_) => onToggle());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: milestone.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    '${milestone.weightage}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(milestone.description),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: _getMilestoneDateColor(theme, milestone.dueDate, milestone.isCompleted),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(milestone.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getMilestoneDateColor(theme, milestone.dueDate, milestone.isCompleted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMilestoneDateColor(ThemeData theme, DateTime dueDate, bool isCompleted) {
    if (isCompleted) return theme.colorScheme.primary;
    
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return theme.colorScheme.error;
    if (dueDate.difference(now).inDays <= 7) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}
