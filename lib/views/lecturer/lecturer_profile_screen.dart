import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/lecturer_viewmodel.dart';

class LecturerProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const LecturerProfileScreen({
    Key? key,
    this.onLogout,
  }) : super(key: key);

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  late LecturerViewModel _viewModel;
  bool _isInit = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<LecturerViewModel>(context);
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
          // Profile data hasn't been loaded yet, trigger fetch
          // Using Future.microtask to prevent setState during build
          Future.microtask(() => viewModel.fetchLecturerData());
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Loading profile data...',
                  style: theme.textTheme.titleMedium,
                ),
                if (viewModel.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${viewModel.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchLecturerData(),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          );        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await viewModel.fetchLecturerData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile refreshed'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                              child: Text(
                                profile['name']?.toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('') ?? 'L',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [                                  Text(
                                    profile['name'] ?? 'Lecturer',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile['title'] ?? 'Lecturer',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile['department'] ?? 'Department',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),                        _buildContactRow(
                          context, 
                          theme, 
                          Icons.email_outlined, 
                          'Email', 
                          profile['email'] ?? 'No email provided',
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(
                          context, 
                          theme, 
                          Icons.access_time, 
                          'Office Hours', 
                          profile['officeHours'] ?? 'Not specified',
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(
                          context, 
                          theme, 
                          Icons.location_on_outlined, 
                          'Office', 
                          profile['office'] ?? 'Not specified',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                _showEditProfileDialog(context, theme, profile);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bio section
                if (profile['bio'] != null && profile['bio'].isNotEmpty) ...[
                  Text(
                    'Biography',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        profile['bio'],
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),                ],
                
                // Account actions
                Text(
                  'Account',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.password_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Change password feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.notifications_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text('Notification Settings'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification settings coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: theme.colorScheme.error,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          onTap: widget.onLogout,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContactRow(
    BuildContext context, 
    ThemeData theme, 
    IconData icon, 
    String label, 
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
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
      ],
    );
  }
    Widget _buildSpecializationCard(
    BuildContext context, 
    ThemeData theme, 
    Map<String, dynamic> specialization,
  ) {
    // Choose a color based on level
    Color levelColor;
    final level = specialization['level'] as String?;
    switch (level) {
      case 'Expert':
        levelColor = Colors.green;
        break;
      case 'Advanced':
        levelColor = Colors.blue;
        break;
      case 'Intermediate':
        levelColor = Colors.orange;
        break;
      default:
        levelColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [                            Text(
                              specialization['name'] ?? 'Specialization',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: levelColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    specialization['level'] ?? 'Beginner',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: levelColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showEditSpecializationDialog(context, theme, specialization);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        _showDeleteSpecializationDialog(context, theme, specialization);
                      },
                    ),
                  ],
                ),
              ],
            ),            if (specialization['description'] is String && (specialization['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                specialization['description'] as String,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showEditProfileDialog(BuildContext context, ThemeData theme, Map<String, dynamic> profile) {
    final nameController = TextEditingController(text: profile['name']);
    final titleController = TextEditingController(text: profile['title']);
    final departmentController = TextEditingController(text: profile['department']);
    final officeController = TextEditingController(text: profile['office']);
    final officeHoursController = TextEditingController(text: profile['officeHours']);
    final bioController = TextEditingController(text: profile['bio']);
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Professor, Associate Professor',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: officeController,
                  decoration: const InputDecoration(
                    labelText: 'Office Location',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your office location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: officeHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Office Hours',
                    hintText: 'e.g. Monday-Wednesday 2-4 PM',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your office hours';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Biography',
                    hintText: 'Tell students about your background and research interests',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // In a real app: save to Firebase
                _viewModel.updateProfile(
                  nameController.text,
                  titleController.text,
                  departmentController.text,
                  officeController.text,
                  officeHoursController.text,
                  bioController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showAddSpecializationDialog(BuildContext context, ThemeData theme) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String level = 'Intermediate'; // Default level
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Specialization'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Machine Learning, Web Development',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Briefly describe your expertise in this area',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expertise Level',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'Beginner',
                              label: Text('Beginner'),
                            ),
                            ButtonSegment<String>(
                              value: 'Intermediate',
                              label: Text('Intermediate'),
                            ),
                            ButtonSegment<String>(
                              value: 'Advanced',
                              label: Text('Advanced'),
                            ),
                            ButtonSegment<String>(
                              value: 'Expert',
                              label: Text('Expert'),
                            ),
                          ],
                          selected: {level},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              level = newSelection.first;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _viewModel.addSpecialization(
                  nameController.text,
                  descriptionController.text,
                  level,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Specialization added successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
    void _showEditSpecializationDialog(BuildContext context, ThemeData theme, Map<String, dynamic> specialization) {
    final nameController = TextEditingController(text: specialization['name']?.toString() ?? '');
    final descriptionController = TextEditingController(text: specialization['description']?.toString() ?? '');
    String level = specialization['level']?.toString() ?? 'Intermediate'; // Current level
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Specialization'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expertise Level',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'Beginner',
                              label: Text('Beginner'),
                            ),
                            ButtonSegment<String>(
                              value: 'Intermediate',
                              label: Text('Intermediate'),
                            ),
                            ButtonSegment<String>(
                              value: 'Advanced',
                              label: Text('Advanced'),
                            ),
                            ButtonSegment<String>(
                              value: 'Expert',
                              label: Text('Expert'),
                            ),
                          ],
                          selected: {level},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              level = newSelection.first;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _viewModel.updateSpecialization(
                  specialization['id'],
                  nameController.text,
                  descriptionController.text,
                  level,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Specialization updated successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
    void _showDeleteSpecializationDialog(BuildContext context, ThemeData theme, Map<String, dynamic> specialization) {
    final specializationName = specialization['name']?.toString() ?? 'Unknown';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Specialization'),
        content: Text(
          'Are you sure you want to delete the "$specializationName" specialization? This action cannot be undone.',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _viewModel.removeSpecialization(specialization['id']);
              Navigator.pop(context);              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${specialization['name'] ?? 'Specialization'} removed successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
