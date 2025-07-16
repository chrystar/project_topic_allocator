import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/student_viewmodel.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const int _interestsTabIndex = 1;
  static const int _recommendationsTabIndex = 2;
  bool _isInit = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final studentViewModel = Provider.of<StudentViewModel>(context, listen: false);
      // Load student data
      Future.microtask(() {
        studentViewModel.fetchStudentProfile();
        studentViewModel.fetchStudentTopicData();
      });
      _isInit = true;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<StudentViewModel>(
      builder: (context, studentViewModel, child) {
        final theme = Theme.of(context);
        
        // Show loading state while data is loading
        if (studentViewModel.isLoading || studentViewModel.isProfileLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Dashboard'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Get student data from view model
        final studentProfile = studentViewModel.studentProfile;
        final studentName = studentProfile?['name'] ?? 'Student';
        final hasAllocatedTopic = studentViewModel.hasAllocatedTopic;
        final allocatedTopic = studentViewModel.allocatedTopic;
        final hasPendingRequests = studentViewModel.hasPendingRequests;
          return Scaffold(
          appBar: AppBar(
            title: const Text('Student Dashboard'),
          ),
          bottomSheet: _buildIncompleteProfileSheet(context, theme, studentProfile),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                studentViewModel.fetchStudentProfile(),
                studentViewModel.fetchStudentTopicData(),
              ]);
            },            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16.0, 
                16.0, 
                16.0, 
                _hasIncompleteProfile(studentProfile) ? 100.0 : 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section
                  _buildGreetingCard(context, theme, studentName, studentProfile),
                  const SizedBox(height: 16),
                  
                  // Topic status section
                  if (hasAllocatedTopic && allocatedTopic != null)
                    _buildAllocatedTopicCard(context, theme, allocatedTopic, studentViewModel)
                  else if (hasPendingRequests)
                    _buildPendingRequestCard(context, theme, studentViewModel)
                  else
                    _buildNoTopicCard(context, theme),
                  
                  const SizedBox(height: 16),
                  
                  // Quick actions
                  _buildQuickActionsSection(context, theme),
                  
                  const SizedBox(height: 16),
                  
                  // Resources section
                  _buildResourcesSection(context, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
    Widget _buildGreetingCard(BuildContext context, ThemeData theme, String name, Map<String, dynamic>? profile) {
    final hour = DateTime.now().hour;
    String greeting = 'Good ';
    
    if (hour < 12) {
      greeting += 'Morning';
    } else if (hour < 17) {
      greeting += 'Afternoon';
    } else {
      greeting += 'Evening';
    }
    
    // Get additional profile info
    final studentId = profile?['studentId'] ?? 'Not set';
    final department = profile?['department'] ?? 'Not set';
    
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $name!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCurrentDateFormatted(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                      if (studentId != 'Not set') ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: $studentId • $department',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildAllocatedTopicCard(BuildContext context, ThemeData theme, Map<String, dynamic> topic, StudentViewModel viewModel) {
    final supervisorData = viewModel.supervisorData;
    final supervisorName = supervisorData?['name'] ?? 'Unknown Supervisor';
    final status = topic['status'] ?? 'Allocated';
    
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
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Project Topic',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(theme, status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getStatusTextColor(theme, status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topic['title'] ?? 'Unknown Topic',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (topic['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                topic['description'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Supervisor: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  supervisorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  status == 'Pending Approval' ? 'Requested: ' : 'Allocated: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDate(status == 'Pending Approval' ? topic['dateRequested'] : topic['dateAllocated']),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                navigationModel.navigate(3); // Topic tab index
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoTopicCard(BuildContext context, ThemeData theme) {
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
            Row(
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Project Topic',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Not Allocated',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You have not been allocated a project topic yet.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your research interests to be allocated a topic.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(                onPressed: () {
                  final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                  navigationModel.navigate(_interestsTabIndex);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Select Interests'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(                onPressed: () {
                  final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                  navigationModel.navigate(_recommendationsTabIndex);
                },
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Browse Available Projects'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildQuickActionsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
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
                icon: Icons.list_alt,
                title: 'My Interests',                onTap: () {
                  final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                  navigationModel.navigate(_interestsTabIndex);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.recommend,
                title: 'Find Projects',                onTap: () {
                  final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                  navigationModel.navigate(_recommendationsTabIndex);
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
                theme,                icon: Icons.people_outline,
                title: 'Lecturers',
                onTap: () {
                  final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
                  navigationModel.navigate(4); // Navigate to lecturers screen
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.forum_outlined,
                title: 'Messages',
                onTap: () {
                  Navigator.pushNamed(context, '/student/messages');
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
                icon: Icons.help_outline,
                title: 'Support',
                onTap: () {
                  Navigator.pushNamed(context, '/student/support');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(),  // Empty container to maintain grid layout
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildResourcesSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Resources',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildResourceCard(
          context,
          theme,
          icon: Icons.book_outlined,
          title: 'Project Guidelines',
          description: 'Learn about the project requirements and guidelines.',
          onTap: () {
            Navigator.pushNamed(context, '/student/guidelines');
          },
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          context,
          theme,
          icon: Icons.calendar_month_outlined,
          title: 'Important Dates',
          description: 'View submission deadlines and other important dates.',
          onTap: () {
            Navigator.pushNamed(context, '/student/dates');
          },
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
  
  Widget _buildResourceCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
    Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'Allocated':
        return theme.colorScheme.primaryContainer;
      case 'Pending Approval':
      case 'Pending':
        return theme.colorScheme.tertiaryContainer;
      case 'Rejected':
        return theme.colorScheme.errorContainer;
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }
  
  Color _getStatusTextColor(ThemeData theme, String status) {
    switch (status) {
      case 'Allocated':
        return theme.colorScheme.onPrimaryContainer;
      case 'Pending Approval':
      case 'Pending':
        return theme.colorScheme.onTertiaryContainer;
      case 'Rejected':
        return theme.colorScheme.onErrorContainer;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
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
    String _formatDate(dynamic date) {
    if (date == null) return 'Not set';
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _buildPendingRequestCard(BuildContext context, ThemeData theme, StudentViewModel viewModel) {
    final pendingRequests = viewModel.pendingRequests;
    if (pendingRequests.isEmpty) return const SizedBox.shrink();
    
    final firstRequest = pendingRequests.first;
    final topicTitle = firstRequest['topicTitle'] ?? 'Unknown Topic';
    final dateRequested = firstRequest['dateRequested'];
    
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
            Row(
              children: [
                Icon(
                  Icons.pending_actions,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pending Request',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Pending Approval',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topicTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Requested: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDate(dateRequested),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (pendingRequests.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.list,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pendingRequests.length} pending requests',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Your request is being reviewed by the lecturer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget? _buildIncompleteProfileSheet(BuildContext context, ThemeData theme, Map<String, dynamic>? profile) {
    if (profile == null) return null;

    final name = profile['name'] as String? ?? '';
    final department = profile['department'] as String? ?? '';
    final level = profile['level'] as String? ?? '';

    if (name.isNotEmpty && department.isNotEmpty && level.isNotEmpty) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final navigationModel = Provider.of<NavigationViewModel>(context, listen: false);
            navigationModel.navigate(5); // Navigate to profile screen
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMissingFieldsMessage(name, department, level),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMissingFieldsMessage(String name, String department, String level) {
    List<String> missing = [];
    if (name.isEmpty) missing.add('name');
    if (department.isEmpty) missing.add('department');
    if (level.isEmpty) missing.add('level');

    if (missing.length == 1) {
      return 'Please add your ${missing[0]}';
    } else if (missing.length == 2) {
      return 'Please add your ${missing[0]} and ${missing[1]}';
    } else {
      return 'Please complete your profile information';
    }
  }

  bool _hasIncompleteProfile(Map<String, dynamic>? profile) {
    if (profile == null) return true;

    final name = profile['name'] as String? ?? '';
    final department = profile['department'] as String? ?? '';
    final level = profile['level'] as String? ?? '';

    return name.isEmpty || department.isEmpty || level.isEmpty;
  }
}
