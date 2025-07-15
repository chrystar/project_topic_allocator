import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/allocation_viewmodel.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../viewmodels/lecturer_viewmodel.dart';
import 'student_interests_screen.dart';

class ProjectRecommendationsScreen extends StatefulWidget {
  const ProjectRecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectRecommendationsScreen> createState() => _ProjectRecommendationsScreenState();
}

class _ProjectRecommendationsScreenState extends State<ProjectRecommendationsScreen> {
  bool _isLoading = true;
  bool _hasInterests = false;
  List<Map<String, dynamic>> _recommendedProjects = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check if the student has saved interests
      final studentViewModel = Provider.of<StudentViewModel>(context, listen: false);
      final interests = await studentViewModel.fetchStudentInterests();
      
      if (interests.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasInterests = false;
        });
        return;
      }
      
      setState(() {
        _hasInterests = true;
      });
        // Get enhanced recommendations based on interests
      final allocationViewModel = Provider.of<AllocationViewModel>(context, listen: false);      final userId = studentViewModel.currentUserId;
      final lecturerViewModel = Provider.of<LecturerViewModel>(context, listen: false);
      
      if (userId != null) {
        // Initialize real-time updates
        allocationViewModel.initializeRealtimeUpdates(userId, lecturerViewModel);
        
        try {
          // Initial load using comprehensive matching
          final matchResults = await allocationViewModel.findComprehensiveMatches(userId);
          final recommendations = matchResults['projects'] as List<Map<String, dynamic>>;
          
          setState(() {
            _recommendedProjects = recommendations;
            _isLoading = false;
          });
        } catch (matchError) {
          // Fall back to basic matching if comprehensive fails
          print('Warning: Enhanced matching failed, falling back to basic matching: $matchError');
          final recommendations = await allocationViewModel.findMatchingProjects(userId);
          
          setState(() {
            _recommendedProjects = recommendations;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Recommendations'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRecommendations,
            tooltip: 'Refresh Recommendations',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }
  
  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading recommendations',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (!_hasInterests) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.interests,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No Interests Selected',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please select your research interests first to get project recommendations that match your preferences.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),              ElevatedButton.icon(                onPressed: () {
                  // Navigate to interests screen maintaining provider context
                  _navigateToInterests();
                },
                icon: const Icon(Icons.edit),
                label: const Text('Set Research Interests'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_recommendedProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No Project Recommendations',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'There are currently no available projects that match your research interests. Please check back later or adjust your interests.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),              ElevatedButton.icon(                onPressed: _navigateToInterests,
                icon: const Icon(Icons.edit),
                label: const Text('Modify Interests'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show recommendations list
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _recommendedProjects.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header card with explanation
            return Card(
              color: theme.colorScheme.primaryContainer,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Project Recommendations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your research interests, we\'ve found the following projects that might be a good fit for you. Projects are sorted by match quality.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Project recommendation cards
          final project = _recommendedProjects[index - 1];
          final matchPercentage = project['matchPercentage'].round();
          final matchingAreas = List<String>.from(project['matchingAreas']);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match percentage indicator
                LinearProgressIndicator(
                  value: matchPercentage / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: _getMatchColor(theme, matchPercentage),
                  minHeight: 8,
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      // Match percentage and title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getMatchColor(theme, matchPercentage).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getMatchColor(theme, matchPercentage),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$matchPercentage% Match',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getMatchColor(theme, matchPercentage),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              project['title'],
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        project['description'],
                        style: theme.textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Matching areas section
                      Text(
                        'Matching Research Areas:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: matchingAreas.map((area) => Chip(
                          label: Text(area),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        )).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lecturer info
                      ListTile(
                        contentPadding: EdgeInsets.zero,                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            project['lecturer']['name'].substring(0, 1),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        title: Text(
                          'Supervisor: ${project['lecturer']['name']}',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          project['lecturer']['email'],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              // Show detailed project info
                              _showProjectDetails(project);
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Details'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () {
                              // Request this project
                              _requestProject(project);
                            },
                            icon: const Icon(Icons.bookmark),
                            label: const Text('Request'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Color _getMatchColor(ThemeData theme, int percentage) {
    if (percentage >= 80) {
      return Colors.green.shade700;
    } else if (percentage >= 60) {
      return theme.colorScheme.primary;
    } else if (percentage >= 40) {
      return Colors.orange;
    } else {
      return Colors.red.shade400;
    }
  }
  
  void _showProjectDetails(Map<String, dynamic> project) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and close button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project['title'],
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Match percentage
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _getMatchColor(theme, project['matchPercentage'].round()),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project['matchPercentage'].round()}% Match with your interests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _getMatchColor(theme, project['matchPercentage'].round()),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description section
                  Text(
                    'Project Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project['description'],
                    style: theme.textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Technologies section
                  Text(
                    'Technologies',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (project['technologies'] as List<String>).map((tech) => Chip(
                      label: Text(tech),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Research areas
                  Text(
                    'Research Areas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (project['areas'] as List<String>).map((area) {
                      final isMatching = (project['matchingAreas'] as List<String>).contains(area);
                      return Chip(
                        label: Text(area),
                        backgroundColor: isMatching 
                          ? theme.colorScheme.secondaryContainer 
                          : theme.colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isMatching 
                            ? theme.colorScheme.onSecondaryContainer 
                            : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isMatching ? FontWeight.bold : null,
                        ),
                        avatar: isMatching ? Icon(
                          Icons.star,
                          size: 18,
                          color: theme.colorScheme.onSecondaryContainer,
                        ) : null,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Supervisor details
                  Text(
                    'Supervisor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              project['lecturer']['name'].substring(0, 1),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project['lecturer']['name'],
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project['lecturer']['email'],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Request button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _requestProject(project);
                      },
                      icon: const Icon(Icons.bookmark),
                      label: const Text('Request This Project'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
    Future<void> _requestProject(Map<String, dynamic> project) async {
    final theme = Theme.of(context);
    final studentViewModel = Provider.of<StudentViewModel>(context, listen: false);
    final allocationViewModel = Provider.of<AllocationViewModel>(context, listen: false);

    // First check if user is logged in
    final studentId = studentViewModel.currentUserId;
    if (studentId == null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('You must be logged in to request a project'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Project'),
        content: Text(
          'Do you want to request the project "${project['title']}"? If approved, this project will be allocated to you.',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Request Project'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    BuildContext? loadingDialogContext;
    
    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingDialogContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Requesting project...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final success = await allocationViewModel.allocateProjectToStudent(
        studentId: studentId,
        topicId: project['id'],
        lecturerId: project['lecturer']['id'],
      );

      if (!mounted) return;

      // Close loading dialog
      if (loadingDialogContext != null && Navigator.canPop(loadingDialogContext!)) {
        Navigator.pop(loadingDialogContext!);
      }

      if (success) {
        await showDialog(
          context: context,
          builder: (successContext) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              'You have successfully requested the project "${project['title']}". You will be notified when the lecturer approves your request.',
              style: theme.textTheme.bodyLarge,
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(successContext);
                  Navigator.pushReplacementNamed(context, '/student/topic');
                },
                child: const Text('View My Topic'),
              ),
            ],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (errorContext) => AlertDialog(
            title: const Text('Request Failed'),
            content: Text(
              'Unable to request the project. ${allocationViewModel.error ?? "Unknown error"}',
              style: theme.textTheme.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(errorContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Make sure loading dialog is closed
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (errorContext) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'An error occurred while requesting the project: ${e.toString()}',
            style: theme.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(errorContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  void _navigateToInterests() async {
    // Get current providers
    final studentVM = Provider.of<StudentViewModel>(context, listen: false);
    final allocationVM = Provider.of<AllocationViewModel>(context, listen: false);
    final lecturerVM = Provider.of<LecturerViewModel>(context, listen: false);
    
    // Navigate to interests screen with providers
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: studentVM),
            ChangeNotifierProvider.value(value: allocationVM),
            ChangeNotifierProvider.value(value: lecturerVM),
          ],
          child: const StudentInterestsScreen(),
        ),
      ),
    );
    
    // Reload recommendations after returning
    if (mounted) {
      _loadRecommendations();
    }
  }
}
