import 'package:flutter/material.dart';
import '../../models/milestone.dart';
import 'milestone_card.dart';

class StatefulMilestoneListItem extends StatefulWidget {
  final Milestone milestone;
  final Function(Milestone) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StatefulMilestoneListItem({
    Key? key,
    required this.milestone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<StatefulMilestoneListItem> createState() => _StatefulMilestoneListItemState();
}

class _StatefulMilestoneListItemState extends State<StatefulMilestoneListItem> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.milestone.isCompleted;
  }

  @override
  void didUpdateWidget(StatefulMilestoneListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.milestone.isCompleted != widget.milestone.isCompleted) {
      setState(() {
        _isCompleted = widget.milestone.isCompleted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MilestoneCard(
      milestone: widget.milestone,
      onToggle: () {
        setState(() {
          _isCompleted = !_isCompleted;
        });
        widget.onToggle(widget.milestone);
      },
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }
}
