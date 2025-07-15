import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/lecturer_viewmodel.dart';

class LecturerSpecializationsScreen extends StatefulWidget {
  const LecturerSpecializationsScreen({Key? key}) : super(key: key);

  @override
  State<LecturerSpecializationsScreen> createState() => _LecturerSpecializationsScreenState();
}

class _LecturerSpecializationsScreenState extends State<LecturerSpecializationsScreen> {
  final List<String> _selectedSpecializations = [];
  bool _isSaving = false;
  
  // Example list of available research areas
  final List<String> _availableSpecializations = [
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
    'Distributed Systems',
    'Parallel Computing',
    'High Performance Computing',
    'Quantum Computing',
    'Bioinformatics',
    'Robotics',
    'Data Mining',
    'Big Data',
    'Computer Graphics',
    'Information Retrieval',
  ];
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _loadLecturerSpecializations());
  }Future<void> _loadLecturerSpecializations() async {
    if (!mounted) return;
    
    try {
      final viewModel = Provider.of<LecturerViewModel>(context, listen: false);
      final specializations = await viewModel.fetchLecturerSpecializations();
      
      if (specializations.isNotEmpty && mounted) {
        setState(() {
          _selectedSpecializations.clear();
          _selectedSpecializations.addAll(specializations);
        });
      }
      
      // Check for errors from the viewModel
      if (viewModel.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading specializations: ${viewModel.error}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading specializations: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  Future<void> _saveSpecializations() async {
    if (_selectedSpecializations.isEmpty || _selectedSpecializations.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 specialization areas'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final viewModel = Provider.of<LecturerViewModel>(context, listen: false);
    
    // Check if user is authenticated
    if (viewModel.currentUserId == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication error. Please log in again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveSpecializations,
              textColor: Colors.white,
            ),
          ),
        );
      }
      return;
    }
    
    try {
      await viewModel.saveLecturerSpecializations(_selectedSpecializations);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Specializations saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving specializations: ${e.toString()}'),
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Specializations'),
        actions: [
          // Save button
          _isSaving 
            ? Center(
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
              )
            : TextButton.icon(
                onPressed: _selectedSpecializations.isEmpty ? null : _saveSpecializations,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
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
                      'Select your research specialization areas below. These will help match you with students who have similar research interests. Choose at least 2 areas and up to 8 that represent your expertise.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${_selectedSpecializations.length}/8',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Your specializations will be visible to students and used for topic allocation.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search specializations',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                // Implement search filtering if needed
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List of specialization areas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _availableSpecializations.length,
              itemBuilder: (context, index) {
                final specialization = _availableSpecializations[index];
                final isSelected = _selectedSpecializations.contains(specialization);
                
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
                        ? theme.colorScheme.secondary 
                        : theme.colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSpecializations.remove(specialization);
                        } else {
                          if (_selectedSpecializations.length < 8) {
                            _selectedSpecializations.add(specialization);
                          } else {
                            // Show warning that max is reached
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You can select up to 8 specialization areas'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0, 
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected 
                              ? theme.colorScheme.secondary 
                              : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              specialization,
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
