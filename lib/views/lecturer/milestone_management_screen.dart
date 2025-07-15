import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/milestone.dart';
import '../../viewmodels/milestone_viewmodel.dart';
import 'package:intl/intl.dart';
import 'milestone_card.dart';
import 'stateful_milestone_list_item.dart';

class MilestoneManagementScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const MilestoneManagementScreen({
    Key? key,
    required this.topicId,
    required this.topicTitle,
  }) : super(key: key);

  @override
  State<MilestoneManagementScreen> createState() => _MilestoneManagementScreenState();
}

class _MilestoneManagementScreenState extends State<MilestoneManagementScreen> {
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

  void _showAddMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        topicId: widget.topicId,
        onSave: _viewModel.addMilestone,
      ),
    );
  }

  void _showEditMilestoneDialog(Milestone milestone) {
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        topicId: widget.topicId,
        milestone: milestone,
        onSave: (topicId, milestone) => 
          _viewModel.editMilestone(topicId, milestone.id, milestone),
      ),
    );
  }  void _toggleMilestoneStatus(Milestone milestone) {
    try {
      _viewModel.updateMilestoneStatus(
        widget.topicId,
        milestone.id,
        !milestone.isCompleted,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update milestone: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Milestone milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: Text('Are you sure you want to delete "${milestone.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _viewModel.deleteMilestone(widget.topicId, milestone.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Milestones: ${widget.topicTitle}'),
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
                    'Add milestones to track project progress',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showAddMilestoneDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
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
                          'Overall Progress',
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
                    return StatefulMilestoneListItem(
                      milestone: milestone,
                      onToggle: _toggleMilestoneStatus,
                      onEdit: () => _showEditMilestoneDialog(milestone),
                      onDelete: () => _showDeleteConfirmation(milestone),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMilestoneDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MilestoneDialog extends StatefulWidget {
  final String topicId;
  final Milestone? milestone;
  final Future<void> Function(String topicId, Milestone milestone) onSave;

  const _MilestoneDialog({
    required this.topicId,
    required this.onSave,
    this.milestone,
  });

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late int _weightage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.milestone?.title ?? '');
    _descriptionController = TextEditingController(text: widget.milestone?.description ?? '');
    _dueDate = widget.milestone?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _weightage = widget.milestone?.weightage ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.milestone == null ? 'Add Milestone' : 'Edit Milestone'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter milestone title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter milestone description',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Due Date: ${DateFormat('MMM d, yyyy').format(_dueDate)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weightage: $_weightage%',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (_weightage > 0) _weightage--;
                    }),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (_weightage < 100) _weightage++;
                    }),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final milestone = Milestone(
                id: widget.milestone?.id ?? '',
                title: _titleController.text,
                description: _descriptionController.text,
                dueDate: _dueDate,
                weightage: _weightage,
                isCompleted: widget.milestone?.isCompleted ?? false,
                completedDate: widget.milestone?.completedDate,
                feedback: widget.milestone?.feedback,
              );
              widget.onSave(widget.topicId, milestone);
              Navigator.pop(context);
            }
          },
          child: Text(widget.milestone == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
