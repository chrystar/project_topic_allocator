import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/lecturer_viewmodel.dart';
import '../../viewmodels/milestone_viewmodel.dart';
import 'milestone_management_screen.dart';
import 'milestone_management_screen.dart';

class LecturerTopicsScreen extends StatefulWidget {
  const LecturerTopicsScreen({Key? key}) : super(key: key);

  @override
  State<LecturerTopicsScreen> createState() => _LecturerTopicsScreenState();
}

class _LecturerTopicsScreenState extends State<LecturerTopicsScreen> {
  late LecturerViewModel _viewModel;
  bool _isInit = false;  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<LecturerViewModel>(context);
      // Initialize data from Firestore using microtask to avoid setState during build
      Future.microtask(() {
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
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Project Topics'),
            actions: [              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh topics from Firestore
                  viewModel.fetchLecturerData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Topics refreshed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: viewModel.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(                onRefresh: () async {
                  // Refresh topics from Firestore
                  await viewModel.fetchLecturerData();
                },
                child: viewModel.topics.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTopicsList(context, theme, viewModel),
              ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTopicDialog(context),
            label: const Text('New Topic'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Topics Created Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create project topics for students to select',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddTopicDialog(context),
            child: const Text('Create Your First Topic'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopicsList(BuildContext context, ThemeData theme, LecturerViewModel viewModel) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.topics.length,
      itemBuilder: (context, index) {        final topic = viewModel.topics[index];
        final assignedCount = topic['assignedCount'] ?? 0;
        final maxStudents = topic['maxStudents'] ?? 1;
        final isFullyAssigned = assignedCount >= maxStudents;
        // Convert Firestore Timestamp to DateTime
        final dateCreated = (topic['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: isFullyAssigned ? Colors.green[100] : theme.colorScheme.primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        topic['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isFullyAssigned ? Colors.green[800] : theme.colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFullyAssigned ? Colors.green : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$assignedCount/$maxStudents',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic['description'],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    if (topic['specializations'] != null && (topic['specializations'] as List).isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (topic['specializations'] as List).map((spec) => Chip(
                          label: Text(spec),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        )).toList(),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Created: ${dateFormat.format(dateCreated)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTopicDialog(context, topic),
                              tooltip: 'Edit Topic',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _showDeleteConfirmation(context, topic),
                              tooltip: 'Delete Topic',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ButtonBar(
                children: [
                  // Milestones button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider(
                                create: (_) => MilestoneViewModel(),
                              ),
                            ],
                            child: MilestoneManagementScreen(
                              topicId: topic['id'],
                              topicTitle: topic['title'],
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Milestones'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
    Widget _buildSpecializationsList(List<Map<String, dynamic>> specializations, List<String> selectedSpecializations, StateSetter setState) {
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: specializations.map((spec) {
        // Get area from specialization, default to empty string if null
        final name = (spec['area'] ?? spec['name'] ?? '') as String;
        final isSelected = selectedSpecializations.contains(name);
        
        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedSpecializations.add(name);
              } else {
                selectedSpecializations.remove(name);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTechnologiesList(List<String> availableTechnologies, List<String> selectedTechnologies, StateSetter setState) {
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: availableTechnologies.map((tech) {
        final isSelected = selectedTechnologies.contains(tech);
        
        return FilterChip(
          label: Text(tech),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedTechnologies.add(tech);
              } else {
                selectedTechnologies.remove(tech);
              }
            });
          },
          backgroundColor: Colors.blue.withOpacity(0.1),
          selectedColor: Colors.blue.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue[800] : Colors.blue[600],
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAreasList(List<String> availableAreas, List<String> selectedAreas, StateSetter setState) {
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: availableAreas.map((area) {
        final isSelected = selectedAreas.contains(area);
        
        return FilterChip(
          label: Text(area),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedAreas.add(area);
              } else {
                selectedAreas.remove(area);
              }
            });
          },
          backgroundColor: Colors.green.withOpacity(0.1),
          selectedColor: Colors.green.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? Colors.green[800] : Colors.green[600],
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }void _showAddTopicDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final viewModel = Provider.of<LecturerViewModel>(context, listen: false);
    final theme = Theme.of(context);
    
    String title = '';
    String description = '';
    int maxStudents = 1;
    List<String> selectedSpecializations = [];
    List<String> selectedTechnologies = [];
    List<String> selectedAreas = [];
    
    // Available technologies for project matching
    final List<String> availableTechnologies = [
      'Flutter', 'React', 'Angular', 'Vue.js', 'Node.js', 'Python', 'Java',
      'JavaScript', 'TypeScript', 'C++', 'C#', 'Swift', 'Kotlin', 'React Native',
      'Firebase', 'AWS', 'Docker', 'Kubernetes', 'MongoDB', 'PostgreSQL', 'MySQL',
      'TensorFlow', 'PyTorch', 'Scikit-learn', 'OpenCV', 'Unity', 'Android Studio',
      'Xcode', 'Git', 'REST API', 'GraphQL', 'Socket.IO', 'Spring Boot'
    ];
    
    // Available research/application areas for project matching
    final List<String> availableAreas = [
      'Web Development', 'Mobile App Development', 'Machine Learning', 'Data Science',
      'Artificial Intelligence', 'Computer Vision', 'Natural Language Processing',
      'Cybersecurity', 'Cloud Computing', 'Internet of Things (IoT)', 'Blockchain',
      'Game Development', 'Augmented Reality', 'Virtual Reality', 'Human-Computer Interaction',
      'Software Engineering', 'Database Systems', 'Networking', 'Distributed Systems',
      'Big Data', 'Robotics', 'Bioinformatics', 'Computer Graphics'
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Create New Topic',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                // Form content in scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              helperText: 'Brief title of the project topic',
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                            onSaved: (value) => title = value?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              helperText: 'Detailed description of the project',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                            onSaved: (value) => description = value?.trim() ?? '',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Maximum Students',
                              helperText: 'Maximum number of students that can be assigned',
                            ),
                            value: maxStudents,
                            items: [1, 2, 3, 4, 5].map((number) => DropdownMenuItem(
                              value: number,
                              child: Text('$number'),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  maxStudents = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Technologies Section
                          Text(
                            'Technologies (Select tools, languages, frameworks)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These will be used to match students with relevant technical interests',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTechnologiesList(availableTechnologies, selectedTechnologies, setState),
                          const SizedBox(height: 20),
                          
                          // Areas Section
                          Text(
                            'Application Areas (Select research/application domains)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These will be used to match students with relevant domain interests',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAreasList(availableAreas, selectedAreas, setState),
                          const SizedBox(height: 20),
                          
                          // Specializations Section (Legacy - kept for backward compatibility)
                          Text(
                            'Specializations (Optional - for compatibility)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSpecializationsList(viewModel.specializations, selectedSpecializations, setState),
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    // Validate that at least some technologies or areas are selected
                                    if (selectedTechnologies.isEmpty && selectedAreas.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select at least one technology or application area for better student matching'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    formKey.currentState?.save();
                                    
                                    // Call ViewModel to add topic to Firestore with technologies and areas
                                    viewModel.addTopic(
                                      title, 
                                      description, 
                                      maxStudents, 
                                      selectedSpecializations,
                                      technologies: selectedTechnologies,
                                      areas: selectedAreas,
                                    );
                                    
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Topic "$title" created with ${selectedTechnologies.length} technologies and ${selectedAreas.length} areas'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Create'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showEditTopicDialog(BuildContext context, Map<String, dynamic> topic) {
    final formKey = GlobalKey<FormState>();
    final viewModel = Provider.of<LecturerViewModel>(context, listen: false);
    
    String title = topic['title'];
    String description = topic['description'];
    int maxStudents = topic['maxStudents'];
    List<String> selectedSpecializations = List<String>.from(topic['specializations'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Topic'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          helperText: 'Brief title of the project topic',
                        ),
                        initialValue: title,
                        validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                        onSaved: (value) => title = value?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          helperText: 'Detailed description of the project',
                          alignLabelWithHint: true,
                        ),
                        initialValue: description,
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                        onSaved: (value) => description = value?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Maximum Students',
                          helperText: 'Maximum number of students that can be assigned',
                        ),
                        value: maxStudents,
                        items: [1, 2, 3, 4, 5].map((number) => DropdownMenuItem(
                          value: number,
                          child: Text('$number'),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              maxStudents = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Specializations:'),
                      const SizedBox(height: 8),
                      _buildSpecializationsList(viewModel.specializations, selectedSpecializations, setState),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      
                      // Call ViewModel to update topic in Firestore
                      viewModel.updateTopic(topic['id'], title, description, maxStudents, selectedSpecializations);
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Topic "$title" updated'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> topic) {
    final viewModel = Provider.of<LecturerViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text(
          'Are you sure you want to delete "${topic['title']}"? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),            onPressed: () {
              // Call ViewModel to delete topic from Firestore
              viewModel.removeTopic(topic['id']);
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Topic "${topic['title']}" deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
