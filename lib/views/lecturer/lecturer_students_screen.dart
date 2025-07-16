import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/lecturer_viewmodel.dart';

class LecturerStudentsScreen extends StatefulWidget {
  const LecturerStudentsScreen({Key? key}) : super(key: key);

  @override
  State<LecturerStudentsScreen> createState() => _LecturerStudentsScreenState();
}

class _LecturerStudentsScreenState extends State<LecturerStudentsScreen> {
  late LecturerViewModel _viewModel;
  bool _isInit = false;
  bool _showAllocated = true; // Toggle between allocated and unallocated students
  String _searchQuery = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<LecturerViewModel>(context);
      // Use Future.microtask to avoid setState during build
      Future.microtask(() => _viewModel.fetchProjectRequests());
      _isInit = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LecturerViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
          // Get students and filter based on the toggle
        final students = _showAllocated 
            ? viewModel.assignedStudents 
            : viewModel.projectRequests;
              // Filter based on search
        final filteredStudents = students.where((student) {
          final name = _showAllocated 
              ? (student['name'] ?? '').toString().toLowerCase()
              : (student['studentName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Management'),            actions: [
              // Debug button to clear allocations (for testing)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Allocations'),
                      content: const Text('This will remove all student allocations for testing purposes. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await viewModel.clearAllAllocations();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All allocations cleared'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                tooltip: 'Clear All Allocations (Testing)',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await viewModel.fetchProjectRequests();
                  await viewModel.fetchLecturerData();
                  
                  // Debug: Show what allocations are found
                  print('DEBUG: Found ${viewModel.assignedStudents.length} assigned students');
                  for (var student in viewModel.assignedStudents) {
                    print('Student: ${student['name']}, Topic ID: ${student['topicId']}, Allocation ID: ${student['allocationId']}');
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Student list refreshed - Found ${viewModel.assignedStudents.length} allocated students'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Toggle between allocated/unallocated
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Allocated'),
                            icon: Icon(Icons.check_circle),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Pending'),
                            icon: Icon(Icons.pending),
                          ),
                        ],
                        selected: {_showAllocated},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _showAllocated = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stats summary
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatChip(
                      context, 
                      theme, 
                      Icons.check_circle_outline, 
                      '${viewModel.assignedStudents.length}',
                      'Allocated',
                      theme.colorScheme.primary,
                    ),                    _buildStatChip(
                      context, 
                      theme, 
                      Icons.pending_outlined, 
                      '${viewModel.projectRequests.length}',
                      'Pending',
                      theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
              
              // Divider
              const Divider(),
              
              // Student list
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showAllocated ? Icons.people_alt_outlined : Icons.pending_outlined,
                              size: 56,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showAllocated                              ? 'No allocated students yet' 
                              : 'No pending requests',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showAllocated 
                                  ? 'Students will appear here once allocated to your topics'
                                  : 'When students express interest, they will appear here',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _showAllocated
                              ? _buildAllocatedStudentCard(context, theme, student)
                              : _buildPendingStudentCard(context, theme, student);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatChip(
    BuildContext context, 
    ThemeData theme, 
    IconData icon, 
    String value, 
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildAllocatedStudentCard(BuildContext context, ThemeData theme, Map<String, dynamic> student) {
    // Safely get topic title with fallback
    String topicTitle = 'Unknown Topic';
    try {
      final topic = _viewModel.topics.firstWhere((t) => t['id'] == student['topicId']);
      topicTitle = topic['title'] ?? 'Unknown Topic';
    } catch (e) {
      // Topic not found in lecturer's topics - this might be old/invalid data
      topicTitle = 'Topic Not Found (ID: ${student['topicId']})';
      print('Warning: Topic ${student['topicId']} not found in lecturer topics');
    }
    
    // Helper function to convert Timestamp to DateTime if needed
    DateTime _convertToDateTime(dynamic date) {
      if (date is DateTime) return date;
      if (date is Timestamp) return date.toDate();
      return DateTime.now(); // fallback
    }
    
    final allocationDate = _convertToDateTime(student['allocationDate']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),                  child: Text(
                    student['name']?.toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('') ?? 'S',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        student['name'] ?? 'Unknown Student',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['email'] ?? 'No email',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student['program'] ?? 'Unknown Program'}, Year ${student['year'] ?? 'N/A'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'message':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Messaging feature coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'remove':
                        _showRemoveStudentDialog(context, theme, student);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.message_outlined),
                          SizedBox(width: 8),
                          Text('Send Message'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove_outlined),
                          SizedBox(width: 8),
                          Text('Remove Allocation'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.topic_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Allocated Topic',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 4),
                  Text(
                    topicTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Allocated on ${allocationDate.day}/${allocationDate.month}/${allocationDate.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/lecturer/progress');
                  },
                  icon: const Icon(Icons.assessment_outlined, size: 18),
                  label: const Text('View Progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPendingStudentCard(BuildContext context, ThemeData theme, Map<String, dynamic> request) {
    // Helper function to convert Timestamp to DateTime if needed
    DateTime _convertToDateTime(dynamic date) {
      if (date is DateTime) return date;
      if (date is Timestamp) return date.toDate();
      return DateTime.now(); // fallback
    }
    
    final dateRequested = _convertToDateTime(request['dateRequested']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.tertiary.withOpacity(0.2),                  child: Text(
                    (request['studentName'] ?? 'S').toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(''),
                    style: TextStyle(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        request['studentName'] ?? 'Unknown Student',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),                      Text(
                        request['studentEmail'] ?? 'No email',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Request sent on ${dateRequested.day}/${dateRequested.month}/${dateRequested.year}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.topic_outlined,
                        size: 16,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Requested Topic',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 4),
                  Text(
                    request['topicTitle'] ?? 'Unknown Topic',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (request['requestMessage'] != null && request['requestMessage'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Request Message',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),                    const SizedBox(height: 4),
                    Text(
                      request['requestMessage'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(                  onPressed: () {
                    _showRejectDialog(context, theme, request);
                  },
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(                  onPressed: () {
                    _showApprovalDialog(context, theme, request);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  
  void _showRemoveStudentDialog(BuildContext context, ThemeData theme, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Allocation'),        content: Text(
          'Are you sure you want to remove ${student['name'] ?? 'this student'} from their allocated topic? This action cannot be undone.',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // In a real app: _viewModel.deallocateStudent(student['id'], student['topicId']);
              Navigator.pop(context);              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student['name'] ?? 'Student'} removed from allocation'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  void _showApprovalDialog(BuildContext context, ThemeData theme, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Project Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve ${request['studentName'] ?? 'this student'}\'s request for the following topic?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              request['topicTitle'] ?? 'Unknown Topic',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (request['requestMessage'] != null && request['requestMessage'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Request Message:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request['requestMessage'] ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _viewModel.approveProjectRequest(request['id'], request['studentId'], request['topicId']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request approved for ${request['studentName'] ?? 'Student'}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error approving request: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ThemeData theme, Map<String, dynamic> request) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Project Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject ${request['studentName'] ?? 'this student'}\'s request for "${request['topicTitle'] ?? 'Unknown Topic'}"?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Please provide a reason for rejection...',
                border: OutlineInputBorder(),
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
          TextButton(
            onPressed: () async {
              try {
                await _viewModel.rejectProjectRequest(request['id'], reasonController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request rejected for ${request['studentName'] ?? 'Student'}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error rejecting request: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
