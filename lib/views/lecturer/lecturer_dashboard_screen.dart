import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/lecturer_viewmodel.dart';

class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  late LecturerViewModel _viewModel;
  bool _isInit = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<LecturerViewModel>(context);
      // Schedule the data fetch for after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.fetchLecturerData();
      });
      _isInit = true;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LecturerViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
          if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Check if profile is null and handle it
        final profile = viewModel.lecturerProfile;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not load lecturer profile',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (viewModel.error != null) 
                  Text(
                    viewModel.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.fetchLecturerData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final topics = viewModel.topics;
        final students = viewModel.assignedStudents;
        final pendingAllocations = viewModel.pendingAllocations;
          return Scaffold(
          appBar: AppBar(
            title: const Text('Lecturer Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh data from Firestore
                  viewModel.fetchLecturerData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dashboard refreshed'),
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
              // Refresh data from Firestore
              await viewModel.fetchLecturerData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section
                  _buildGreetingCard(context, theme, profile),
                  const SizedBox(height: 24),
                  
                  // Stats overview
                  _buildStatsOverview(context, theme, topics, students, pendingAllocations),
                  const SizedBox(height: 24),
                  
                  // Recent activity
                  _buildRecentActivity(context, theme, viewModel),
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  _buildQuickActions(context, theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGreetingCard(BuildContext context, ThemeData theme, Map<String, dynamic> profile) {
    final hour = DateTime.now().hour;
    String greeting = 'Good ';
    
    if (hour < 12) {
      greeting += 'Morning';
    } else if (hour < 17) {
      greeting += 'Afternoon';
    } else {
      greeting += 'Evening';
    }
    
    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        '$greeting, ${profile['name']?.toString().split(' ').first ?? 'Lecturer'}!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),                      Text(
                        _getCurrentDateFormatted(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile['title'] ?? 'Lecturer'} • ${profile['department'] ?? 'Department'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.3),                  child: Text(
                    profile['name']?.toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('') ?? 'L',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsOverview(
    BuildContext context, 
    ThemeData theme, 
    List<Map<String, dynamic>> topics, 
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> pendingAllocations
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context, 
                theme, 
                Icons.topic_outlined, 
                topics.length.toString(), 
                'Topics',
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context, 
                theme, 
                Icons.people_outlined, 
                students.length.toString(), 
                'Students',
                theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context, 
                theme, 
                Icons.pending_outlined, 
                pendingAllocations.length.toString(), 
                'Pending',
                theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context, 
                theme, 
                Icons.check_circle_outline, 
                '${topics.where((t) => (t['assignedCount'] ?? 0) >= (t['maxStudents'] ?? 1)).length}/${topics.length}', 
                'Full Topics',
                theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, 
    ThemeData theme, 
    IconData icon, 
    String value, 
    String label,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildRecentActivity(BuildContext context, ThemeData theme, LecturerViewModel viewModel) {
    final pendingAllocations = viewModel.pendingAllocations;
    final recentAllocations = viewModel.assignedStudents;
    
    // Helper function to convert Timestamp to DateTime if needed
    DateTime _convertToDateTime(dynamic date) {
      if (date is DateTime) return date;
      if (date is Timestamp) return date.toDate();
      return DateTime.now(); // fallback
    }
    
    // Sort by date
    final sortedPending = List.from(pendingAllocations)
      ..sort((a, b) => _convertToDateTime(b['dateSubmitted']).compareTo(_convertToDateTime(a['dateSubmitted'])));
    
    final sortedAllocations = List.from(recentAllocations)
      ..sort((a, b) => _convertToDateTime(b['allocationDate']).compareTo(_convertToDateTime(a['allocationDate'])));
      // Take only the most recent 3
    final recentActivity = [
      ...sortedPending.take(2).map((item) => {
        ...item,
        'type': 'interest',
      }),
      ...sortedAllocations.take(2).map((item) => {
        ...item,
        'type': 'allocation',
      }),
    ]..sort((a, b) {
      final DateTime aDate = a['type'] == 'interest' 
          ? _convertToDateTime(a['dateSubmitted'])
          : _convertToDateTime(a['allocationDate']);
      final DateTime bDate = b['type'] == 'interest' 
          ? _convertToDateTime(b['dateSubmitted'])
          : _convertToDateTime(b['allocationDate']);
      return bDate.compareTo(aDate);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: recentActivity.isEmpty 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No recent activity',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )              : Column(
                  children: recentActivity.map((activity) {
                    // Cast to Map<String, dynamic> to fix type error
                    return _buildActivityItem(context, theme, Map<String, dynamic>.from(activity));
                  }).toList(),
                ),
          ),
        ),
      ],
    );
  }
  Widget _buildActivityItem(BuildContext context, ThemeData theme, Map<String, dynamic> activity) {
    final bool isInterest = activity['type'] == 'interest';
    final String studentName = isInterest ? (activity['studentName'] ?? 'Student') : (activity['name'] ?? 'Student');
    final String topicTitle = isInterest ? (activity['topicTitle'] ?? 'Unknown Topic') : 
      (_viewModel.topics.firstWhere((t) => t['id'] == activity['topicId'], orElse: () => {'title': 'Unknown Topic'})['title'] ?? 'Unknown Topic');
    
    // Helper function to convert Timestamp to DateTime if needed
    DateTime _convertToDateTime(dynamic date) {
      if (date is DateTime) return date;
      if (date is Timestamp) return date.toDate();
      return DateTime.now(); // fallback
    }
    
    final DateTime date = isInterest ? _convertToDateTime(activity['dateSubmitted']) : _convertToDateTime(activity['allocationDate']);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isInterest 
                ? theme.colorScheme.tertiaryContainer 
                : theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInterest ? Icons.star_outline : Icons.check_circle_outline,
              color: isInterest 
                ? theme.colorScheme.onTertiaryContainer 
                : theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Text(
                  isInterest 
                    ? '$studentName expressed interest in a topic' 
                    : '$studentName was allocated to a topic',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topicTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: isInterest,
            child: ElevatedButton.icon(
              onPressed: () {
                // Allocate student
                _showAllocationDialog(context, theme, activity);
              },
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Allocate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAllocationDialog(BuildContext context, ThemeData theme, Map<String, dynamic> interest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allocate Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            Text(
              'Are you sure you want to allocate ${interest['studentName'] ?? 'this student'} to the following topic?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              interest['topicTitle'] ?? 'Unknown Topic',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (interest['studentNote'] != null && interest['studentNote'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Student Note:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interest['studentNote'],
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
            onPressed: () {
              _viewModel.allocateStudent(interest['studentId'], interest['topicId']);
              Navigator.pop(context);              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${interest['studentName'] ?? 'Student'} allocated successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.add_circle_outline,
                title: 'New Topic',
                onTap: () {
                  // Navigate to topics tab to add new topic
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.person_add_outlined,
                title: 'Allocate Student',
                onTap: () {
                  // Navigate to students tab
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.edit_outlined,
                title: 'Edit Specializations',
                onTap: () {
                  // Navigate to profile tab
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.message_outlined,
                title: 'Message Students',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Messaging feature coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getCurrentDateFormatted() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final weekday = weekdays[(now.weekday - 1) % 7];
    final month = months[now.month - 1];
    
    return '$weekday, $month ${now.day}, ${now.year}';
  }
  
  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
