import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milestone.dart';
import '../../viewmodels/milestone_viewmodel.dart';

class StudentMilestonesScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const StudentMilestonesScreen({
    Key? key,
    required this.topicId,
    required this.topicTitle,
  }) : super(key: key);

  @override
  State<StudentMilestonesScreen> createState() => _StudentMilestonesScreenState();
}

class _StudentMilestonesScreenState extends State<StudentMilestonesScreen> {
  late MilestoneViewModel _viewModel;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<MilestoneViewModel>(context);
      _viewModel.fetchMilestones(widget.topicId);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _viewModel.stopRealtimeMilestoneUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress: ${widget.topicTitle}'),
      ),
      body: Consumer<MilestoneViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.milestones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No milestones yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your supervisor will add project milestones soon',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Progress',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${(viewModel.getProjectProgress() * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: viewModel.getProjectProgress(),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

              // Milestones list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = viewModel.milestones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(milestone.description),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: _getMilestoneDateColor(
                                        theme,
                                        milestone.dueDate,
                                        milestone.isCompleted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${DateFormat('MMM d, yyyy').format(milestone.dueDate)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _getMilestoneDateColor(
                                          theme,
                                          milestone.dueDate,
                                          milestone.isCompleted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: milestone.isCompleted
                                      ? OutlinedButton.icon(
                                          onPressed: () => _updateMilestoneStatus(milestone, false),
                                          icon: const Icon(Icons.undo),
                                          label: const Text('Mark as Incomplete'),
                                        )
                                      : FilledButton.icon(
                                          onPressed: () => _showCompletionDialog(milestone),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Mark as Complete'),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          if (milestone.feedback != null) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supervisor Feedback:',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    milestone.feedback!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getMilestoneDateColor(ThemeData theme, DateTime dueDate, bool isCompleted) {
    if (isCompleted) return theme.colorScheme.primary;
    if (dueDate.isBefore(DateTime.now())) return theme.colorScheme.error;
    if (dueDate.difference(DateTime.now()).inDays <= 7) return theme.colorScheme.error;
    return theme.colorScheme.onSurfaceVariant;
  }

  void _showCompletionDialog(Milestone milestone) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark "${milestone.title}" as complete?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Add a comment (optional)',
                hintText: 'E.g., Completed all requirements',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _updateMilestoneStatus(
                milestone,
                true,
                comment: commentController.text.isNotEmpty
                    ? commentController.text
                    : null,
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _updateMilestoneStatus(Milestone milestone, bool isCompleted, {String? comment}) {
    _viewModel.updateMilestoneStatus(
      widget.topicId,
      milestone.id,
      isCompleted,
      feedback: comment,
    );
  }
}
