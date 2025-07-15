import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/student_viewmodel.dart';

class StudentTopicScreen extends StatefulWidget {
  const StudentTopicScreen({Key? key}) : super(key: key);

  @override
  State<StudentTopicScreen> createState() => _StudentTopicScreenState();
}

class _StudentTopicScreenState extends State<StudentTopicScreen> {
  late StudentViewModel _viewModel;
  bool _isInit = false;
    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<StudentViewModel>(context);
        // Fetch actual topic data
      _viewModel.fetchStudentTopicData();
      
      _isInit = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<StudentViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
        
        if (viewModel.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project Topic')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Project Topic'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Re-fetch data
                  // _viewModel.fetchStudentTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshed topic data'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // In a real app: await _viewModel.fetchStudentTopicData();
              await Future.delayed(const Duration(seconds: 1));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshed topic data'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: viewModel.hasAllocatedTopic
                ? _buildTopicDetails(context, theme, viewModel)
                : _buildNoTopicView(context, theme),
          ),
        );
      },
    );
  }
  
  Widget _buildTopicDetails(BuildContext context, ThemeData theme, StudentViewModel viewModel) {
    final topic = viewModel.allocatedTopic!;
    final supervisor = viewModel.supervisorData!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(context, theme, topic),
          
          // Topic Card
          _buildTopicCard(context, theme, topic),
          
          // Supervisor Card
          _buildSupervisorCard(context, theme, supervisor),
          
          // Milestones Section
          _buildMilestonesSection(context, theme, viewModel),
          
          // Resources Section
          _buildResourcesSection(context, theme, viewModel),
          
          // Action buttons
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRequestMeetingDialog(context, theme),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Request Meeting with Supervisor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download functionality coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Project Brief'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }
    Widget _buildStatusCard(BuildContext context, ThemeData theme, Map<String, dynamic> topic) {
    final status = topic['status'] ?? 'Unknown';
    final statusMessage = _getStatusMessage(status);
    final showActions = _shouldShowStatusActions(status);
    
    return Card(
      color: _getStatusColor(theme, status),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusTextColor(theme, status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${_getStatusDisplayText(status)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _getStatusTextColor(theme, status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getStatusTextColor(theme, status).withOpacity(0.9),
                        ),
                      ),
                      if (topic['dateAllocated'] != null && status != 'Pending Approval' && status != 'Requested')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Allocated on: ${_formatDate(_convertToDateTime(topic['dateAllocated']))}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusTextColor(theme, status).withOpacity(0.7),
                            ),
                          ),
                        ),
                      if (topic['dateRequested'] != null && (status == 'Pending Approval' || status == 'Requested'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Requested on: ${_formatDate(_convertToDateTime(topic['dateRequested']))}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusTextColor(theme, status).withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 16),
              _buildStatusActions(context, theme, status, topic),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopicCard(BuildContext context, ThemeData theme, Map<String, dynamic> topic) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Topic',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),            Text(
              topic['title'] ?? 'No Title',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              topic['description'] ?? 'No description available',
              style: theme.textTheme.bodyLarge,
            ),
            
            if (topic['objectives'] != null && (topic['objectives'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Objectives',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.from((topic['objectives'] as List).map(
                (objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          objective,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
            
            if (topic['technologies'] != null && (topic['technologies'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Technologies',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.from((topic['technologies'] as List).map(
                  (tech) => Chip(
                    label: Text(tech),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSupervisorCard(BuildContext context, ThemeData theme, Map<String, dynamic> supervisor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisor',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,                  child: Text(
                    (supervisor['name'] ?? 'Unknown').toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(''),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supervisor['name'] ?? 'Unknown Supervisor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        supervisor['department'] ?? 'Unknown Department',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mail_outline),
                  onPressed: () {
                    // Email functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email functionality coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Email supervisor',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Office Hours'),
              subtitle: Text(supervisor['officeHours'] ?? 'Not specified'),
              dense: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Office Location'),
              subtitle: Text(supervisor['office'] ?? 'Not specified'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMilestonesSection(BuildContext context, ThemeData theme, StudentViewModel viewModel) {
    final milestones = viewModel.milestones;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Milestones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Progress indicator
                if (milestones.isNotEmpty)
                  _buildProgressIndicator(context, theme, milestones),
              ],
            ),
            const SizedBox(height: 16),
            if (milestones.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No milestones available yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...milestones.map((milestone) => _buildMilestoneItem(context, theme, milestone, viewModel)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(BuildContext context, ThemeData theme, List<Map<String, dynamic>> milestones) {
    final completedCount = milestones.where((m) => m['completed'] == true).length;
    final totalCount = milestones.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                strokeWidth: 5,
              ),
              Center(
                child: Text(
                  '$completedCount/$totalCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
    Widget _buildMilestoneItem(
    BuildContext context, 
    ThemeData theme, 
    Map<String, dynamic> milestone,
    StudentViewModel viewModel
  ) {
    final bool isCompleted = milestone['completed'] ?? false;
    final DateTime dueDate = _convertToDateTime(milestone['dueDate']);
    final bool isOverdue = !isCompleted && dueDate.isBefore(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showMilestoneDetails(context, theme, milestone, viewModel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            color: isCompleted 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : isOverdue 
                ? theme.colorScheme.errorContainer.withOpacity(0.3)
                : theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted 
                    ? theme.colorScheme.primary 
                    : isOverdue 
                      ? theme.colorScheme.error
                      : theme.colorScheme.surfaceVariant,
                ),
                child: Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    viewModel.toggleMilestoneCompletion(milestone['id']);
                  },
                  fillColor: MaterialStateProperty.resolveWith(
                    (states) => isCompleted 
                      ? theme.colorScheme.primary 
                      : isOverdue 
                        ? theme.colorScheme.error
                        : theme.colorScheme.surfaceVariant,
                  ),
                  checkColor: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    Text(
                      milestone['title'] ?? 'Untitled Milestone',
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${_formatDate(dueDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue 
                          ? theme.colorScheme.error 
                          : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted
                  ? Icons.check_circle_outline
                  : isOverdue
                    ? Icons.error_outline
                    : Icons.arrow_forward_ios,
                color: isCompleted
                  ? theme.colorScheme.primary
                  : isOverdue
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
    void _showMilestoneDetails(
    BuildContext context, 
    ThemeData theme, 
    Map<String, dynamic> milestone,
    StudentViewModel viewModel
  ) {
    final bool isCompleted = milestone['completed'] ?? false;
    final DateTime dueDate = _convertToDateTime(milestone['dueDate']);
    final bool isOverdue = !isCompleted && dueDate.isBefore(DateTime.now());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted 
                      ? theme.colorScheme.primaryContainer 
                      : isOverdue 
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.secondaryContainer,
                  ),
                  child: Icon(
                    isCompleted
                      ? Icons.check
                      : isOverdue
                        ? Icons.warning_amber
                        : Icons.flag,
                    color: isCompleted 
                      ? theme.colorScheme.onPrimaryContainer 
                      : isOverdue 
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milestone['title'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              milestone['description'],
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(dueDate),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isOverdue ? theme.colorScheme.error : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                          ? 'Completed'
                          : isOverdue
                            ? 'Overdue'
                            : 'Pending',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isCompleted
                            ? theme.colorScheme.primary
                            : isOverdue
                              ? theme.colorScheme.error
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // In real app: Add file submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File submission coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Upload Submission'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.toggleMilestoneCompletion(milestone['id']);
                      Navigator.pop(context);
                    },
                    child: Text(isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResourcesSection(BuildContext context, ThemeData theme, StudentViewModel viewModel) {
    final resources = viewModel.resources;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Resources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (resources.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No resources available yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...resources.map((resource) => _buildResourceItem(context, theme, resource)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResourceItem(BuildContext context, ThemeData theme, Map<String, dynamic> resource) {
    IconData icon;
    Color color;
    
    switch (resource['type']) {
      case 'document':
        icon = Icons.description_outlined;
        color = theme.colorScheme.primary;
        break;
      case 'paper':
        icon = Icons.article_outlined;
        color = theme.colorScheme.secondary;
        break;
      case 'template':
        icon = Icons.file_copy_outlined;
        color = theme.colorScheme.tertiary;
        break;
      case 'video':
        icon = Icons.video_library_outlined;
        color = Colors.red;
        break;
      case 'link':
        icon = Icons.link;
        color = Colors.blue;
        break;
      default:
        icon = Icons.insert_drive_file_outlined;
        color = theme.colorScheme.onSurfaceVariant;
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(
        resource['title'],
        style: theme.textTheme.titleMedium,
      ),
      subtitle: resource['author'] != null 
        ? Text('by ${resource['author']}')
        : null,
      trailing: IconButton(
        icon: const Icon(Icons.download_outlined),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download functionality coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        tooltip: 'Download',
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // In real app: Open the resource URL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening resource link (coming soon)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
  
  void _showRequestMeetingDialog(BuildContext context, ThemeData theme) {
    final formKey = GlobalKey<FormState>();
    String subject = '';
    String message = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Meeting with Supervisor'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Project progress discussion',
                ),
                validator: (value) => 
                  value == null || value.isEmpty ? 'Please enter a subject' : null,
                onChanged: (value) => subject = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'I would like to discuss my project progress...',
                ),
                maxLines: 3,
                validator: (value) => 
                  value == null || value.isEmpty ? 'Please enter a message' : null,
                onChanged: (value) => message = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final viewModel = Provider.of<StudentViewModel>(context, listen: false);
                viewModel.requestMeeting(subject, message);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Meeting request sent: "$subject"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
    Widget _buildNoTopicView(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Active Project Assignment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have an active project assignment yet. This could mean:\n\n'
              '• You haven\'t submitted any project requests\n'
              '• Your submitted requests are pending lecturer approval\n'
              '• You need to select your research interests first',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPendingRequestsInfo(context, theme),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/student/recommendations');
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Available Projects'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, 
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/student/interests');
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Update Research Interests'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, 
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking for updates...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                final viewModel = Provider.of<StudentViewModel>(context, listen: false);
                viewModel.fetchStudentTopicData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check for Updates'),
            ),
            const SizedBox(height: 48),
            _buildHelperCard(context, theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingRequestsInfo(BuildContext context, ThemeData theme) {
    // In a real app, this would check for pending requests from the view model
    // For now, we'll show a generic info card
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Check',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If you have submitted project requests, they may be pending lecturer approval. '
              'Check your email for notifications or refresh this page periodically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelperCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'How Topics Are Allocated',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Project topics are allocated based on:',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: [
                  _buildBulletPoint(
                    context, 
                    theme, 
                    'Your selected research interests',
                  ),
                  _buildBulletPoint(
                    context, 
                    theme, 
                    'Academic performance in related courses',
                  ),
                  _buildBulletPoint(
                    context, 
                    theme, 
                    'Availability of supervisors in your area of interest',
                  ),
                  _buildBulletPoint(
                    context, 
                    theme, 
                    'Project topic complexity and prerequisites',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure you select the research interests that best match your skills and career goals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(BuildContext context, ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
    Color _getStatusColor(ThemeData theme, String? status) {
    switch (status) {
      case 'Allocated':
        return theme.colorScheme.primaryContainer;
      case 'In Progress':
        return theme.colorScheme.tertiaryContainer;
      case 'Completed':
        return theme.colorScheme.secondaryContainer;
      case 'Delayed':
        return theme.colorScheme.errorContainer;
      case 'Pending Approval':
      case 'Requested':
        return theme.colorScheme.surfaceVariant.withOpacity(0.8);
      case 'Rejected':
        return theme.colorScheme.errorContainer.withOpacity(0.6);
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }
  
  Color _getStatusTextColor(ThemeData theme, String? status) {
    switch (status) {
      case 'Allocated':
        return theme.colorScheme.onPrimaryContainer;
      case 'In Progress':
        return theme.colorScheme.onTertiaryContainer;
      case 'Completed':
        return theme.colorScheme.onSecondaryContainer;
      case 'Delayed':
        return theme.colorScheme.onErrorContainer;
      case 'Pending Approval':
      case 'Requested':
        return theme.colorScheme.onSurfaceVariant;
      case 'Rejected':
        return theme.colorScheme.onErrorContainer;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
  
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Allocated':
        return Icons.check_circle_outline;
      case 'In Progress':
        return Icons.pending_outlined;
      case 'Completed':
        return Icons.done_all;
      case 'Delayed':
        return Icons.error_outline;
      case 'Pending Approval':
      case 'Requested':
        return Icons.hourglass_empty;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
  String _getStatusDisplayText(String? status) {
    switch (status) {
      case 'Pending Approval':
        return 'Pending Lecturer Approval';
      case 'Requested':
        return 'Request Submitted';
      case 'Rejected':
        return 'Request Rejected';
      default:
        return status ?? 'Unknown';
    }
  }
  
  String _getStatusMessage(String? status) {
    switch (status) {
      case 'Allocated':
        return 'Your project has been approved and allocated to you. You can now start working on it.';
      case 'In Progress':
        return 'Your project is currently in progress. Keep track of your milestones and deadlines.';
      case 'Completed':
        return 'Congratulations! You have successfully completed your project.';
      case 'Delayed':
        return 'Your project is behind schedule. Please contact your supervisor for assistance.';
      case 'Pending Approval':
      case 'Requested':
        return 'Your project request is waiting for lecturer approval. You will be notified once a decision is made.';
      case 'Rejected':
        return 'Your project request was not approved. You can request other available projects.';
      default:
        return 'Status information is not available.';
    }
  }
  
  bool _shouldShowStatusActions(String? status) {
    return status == 'Pending Approval' || status == 'Requested' || status == 'Rejected';
  }
  
  Widget _buildStatusActions(BuildContext context, ThemeData theme, String? status, Map<String, dynamic> topic) {
    switch (status) {
      case 'Pending Approval':
      case 'Requested':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelRequestDialog(context, theme, topic),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _checkRequestStatus(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
              ),
            ),
          ],
        );
      case 'Rejected':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/student/recommendations'),
            icon: const Icon(Icons.search),
            label: const Text('Browse Other Projects'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  void _showCancelRequestDialog(BuildContext context, ThemeData theme, Map<String, dynamic> topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Project Request'),
        content: Text(
          'Are you sure you want to cancel your request for "${topic['title']}"? This action cannot be undone.',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelProjectRequest(topic);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
    void _cancelProjectRequest(Map<String, dynamic> topic) async {
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    final requestId = topic['requestId'];
    
    if (requestId != null) {
      final success = await viewModel.cancelProjectRequest(requestId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project request for "${topic['title']}" has been cancelled'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to cancel request. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Fallback for mock data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project request for "${topic['title']}" has been cancelled'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate back to recommendations
      Navigator.pushReplacementNamed(context, '/student/recommendations');
    }
  }
  
  void _checkRequestStatus(BuildContext context) {
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    viewModel.fetchStudentTopicData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking latest status...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
    DateTime _convertToDateTime(dynamic date) {
    if (date is DateTime) return date;
    if (date is Timestamp) return date.toDate();
    return DateTime.now(); // fallback
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
