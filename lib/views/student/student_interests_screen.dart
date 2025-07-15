import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/student_viewmodel.dart';

class StudentInterestsScreen extends StatefulWidget {
  const StudentInterestsScreen({Key? key}) : super(key: key);

  @override
  State<StudentInterestsScreen> createState() => _StudentInterestsScreenState();
}

class _StudentInterestsScreenState extends State<StudentInterestsScreen> {
  final List<String> _selectedInterests = [];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  
  // Example list of available research interests
  final List<String> _availableInterests = [
    'Artificial Intelligence',
    'Machine Learning',
    'Data Science',
    'Web Development',
    'Mobile App Development',
    'Cloud Computing',
    'Cybersecurity',
    'Blockchain',
    'Internet of Things (IoT)',
    'Human-Computer Interaction',
    'Computer Vision',
    'Natural Language Processing',
    'Software Engineering',
    'Database Systems',
    'Networking',
    'Operating Systems',
    'Embedded Systems',
    'Game Development',
    'Augmented Reality',
    'Virtual Reality',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }
  Future<void> _loadUserInterests() async {
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    final interests = await viewModel.fetchStudentInterests();
    
    if (interests.isNotEmpty) {
      setState(() {
        _selectedInterests.clear();
        _selectedInterests.addAll(interests);
      });
    }
  }
  Future<void> _saveInterests() async {
    if (_selectedInterests.isEmpty || _selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final viewModel = Provider.of<StudentViewModel>(context, listen: false);
    try {
      await viewModel.saveStudentInterests(_selectedInterests);
      
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interests saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Ask user if they'd like to see their project recommendations
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('View Project Recommendations?'),
            content: const Text(
              'Your interests have been saved. Would you like to see project recommendations based on your interests?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to recommendations screen
                  Navigator.pushNamed(context, '/student/recommendations');
                },
                child: const Text('View Recommendations'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interests: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(      appBar: AppBar(
        title: const Text('Research Interests'),
        actions: [
          // Save status / button
          Consumer<StudentViewModel>(
            builder: (context, viewModel, child) {
              final bool interestsSaved = viewModel.interestsSaved && !_hasUnsavedChanges;
              
              if (_isSaving) {
                // Show loading indicator when saving
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              } else if (interestsSaved) {
                // Show saved status when interests are saved
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Show save button when there are changes
                return TextButton.icon(
                  onPressed: _selectedInterests.isEmpty || _selectedInterests.length < 3 
                      ? null 
                      : _saveInterests,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your research interests below. Choose at least 3 and up to 5 interests that match your preferences.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${_selectedInterests.length}/5',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // List of interests
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _availableInterests.length,
              itemBuilder: (context, index) {
                final interest = _availableInterests[index];
                final isSelected = _selectedInterests.contains(interest);
                  final viewModel = Provider.of<StudentViewModel>(context, listen: false);
                final bool interestsSaved = viewModel.interestsSaved && !_hasUnsavedChanges;
                
                return Card(
                  elevation: 0,
                  color: isSelected 
                    ? theme.colorScheme.secondaryContainer 
                    : theme.colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                        ? (interestsSaved ? theme.colorScheme.primary : theme.colorScheme.secondary)
                        : theme.colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final viewModel = Provider.of<StudentViewModel>(context, listen: false);
                      
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest);
                        } else {
                          if (_selectedInterests.length < 5) {
                            _selectedInterests.add(interest);
                          } else {
                            // Show warning that max is reached
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You can select up to 5 interests'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                        }
                        
                        // Mark interests as unsaved when selections change
                        _hasUnsavedChanges = true;
                        viewModel.markInterestsAsUnsaved();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0, 
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [                          Consumer<StudentViewModel>(
                            builder: (context, viewModel, child) {
                              final bool interestsSaved = viewModel.interestsSaved && !_hasUnsavedChanges;
                              
                              return Icon(
                                isSelected 
                                  ? (interestsSaved ? Icons.check_circle : Icons.check_circle_outline)
                                  : Icons.circle_outlined,
                                color: isSelected 
                                  ? (interestsSaved ? theme.colorScheme.primary : theme.colorScheme.secondary)
                                  : theme.colorScheme.onSurfaceVariant,
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              interest,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected 
                                  ? theme.colorScheme.onSecondaryContainer 
                                  : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
