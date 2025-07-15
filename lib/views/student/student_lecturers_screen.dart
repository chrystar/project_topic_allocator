import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/lecturer_viewmodel.dart';

class StudentLecturersScreen extends StatefulWidget {
  const StudentLecturersScreen({Key? key}) : super(key: key);

  @override
  State<StudentLecturersScreen> createState() => _StudentLecturersScreenState();
}

class _StudentLecturersScreenState extends State<StudentLecturersScreen> {
  String _searchQuery = '';
  late LecturerViewModel _viewModel;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<LecturerViewModel>(context);
      _viewModel.fetchLecturers();
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Members'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or specialization...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Lecturers list
          Expanded(
            child: Consumer<LecturerViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
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
                          'Error loading lecturers',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => viewModel.fetchLecturers(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final lecturers = viewModel.allLecturers;
                final filteredLecturers = lecturers.where((lecturer) {
                  final name = (lecturer['name'] ?? '').toString().toLowerCase();
                  final specializations = List<String>.from(lecturer['specializations'] ?? [])
                      .map((s) => s.toLowerCase())
                      .toList();
                  
                  return name.contains(_searchQuery) ||
                      specializations.any((s) => s.contains(_searchQuery));
                }).toList();

                if (filteredLecturers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No lecturers found'
                              : 'No lecturers match your search',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.fetchLecturers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLecturers.length,
                    itemBuilder: (context, index) {
                      final lecturer = filteredLecturers[index];
                      final specializations = List<String>.from(lecturer['specializations'] ?? []);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _showLecturerDetails(lecturer),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary,
                                      child: Text(
                                        lecturer['name']?.substring(0, 1) ?? '?',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lecturer['name'] ?? 'Unknown',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            lecturer['title'] ?? 'Faculty Member',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (specializations.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: specializations.map((specialization) {
                                      final isHighlighted = _searchQuery.isNotEmpty &&
                                          specialization.toLowerCase().contains(_searchQuery);
                                      
                                      return Chip(
                                        label: Text(specialization),
                                        backgroundColor: isHighlighted
                                            ? theme.colorScheme.primaryContainer
                                            : theme.colorScheme.surfaceVariant,
                                        labelStyle: TextStyle(
                                          color: isHighlighted
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.colorScheme.onSurfaceVariant,
                                          fontWeight: isHighlighted
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLecturerDetails(Map<String, dynamic> lecturer) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with lecturer info
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              lecturer['name']?.substring(0, 1) ?? '?',
                              style: TextStyle(
                                fontSize: 24,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lecturer['name'] ?? 'Unknown',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  lecturer['title'] ?? 'Faculty Member',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (lecturer['bio'] != null && lecturer['bio'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'About',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lecturer['bio'],
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),

                // Contact information
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContactTile(
                        theme,
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: lecturer['email'] ?? 'Not available',
                      ),
                      const SizedBox(height: 12),
                      _buildContactTile(
                        theme,
                        icon: Icons.business_outlined,
                        title: 'Department',
                        value: lecturer['department'] ?? 'Not available',
                      ),
                      const SizedBox(height: 12),
                      _buildContactTile(
                        theme,
                        icon: Icons.location_on_outlined,
                        title: 'Office',
                        value: lecturer['office'] ?? 'Not available',
                      ),
                      const SizedBox(height: 12),
                      _buildContactTile(
                        theme,
                        icon: Icons.access_time_outlined,
                        title: 'Office Hours',
                        value: lecturer['officeHours'] ?? 'Not available',
                      ),
                    ],
                  ),
                ),

                // Specializations
                if (lecturer['specializations'] != null &&
                    (lecturer['specializations'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Areas of Expertise',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (lecturer['specializations'] as List)
                              .map((specialization) => Chip(
                                    label: Text(specialization),
                                    backgroundColor: theme.colorScheme.surfaceVariant,
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
