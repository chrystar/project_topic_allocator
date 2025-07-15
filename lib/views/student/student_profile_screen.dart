import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/student_viewmodel.dart';

class StudentProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const StudentProfileScreen({
    Key? key,
    this.onLogout,
  }) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentViewModel _viewModel;
  bool _isInit = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _viewModel = Provider.of<StudentViewModel>(context);
      _viewModel.fetchStudentProfile();
      _isInit = true;
    }
  }
    final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
  // Form fields
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _levelController;
    @override
  void initState() {
    super.initState();
    // Initialize with empty values, will be updated in didChangeDependencies
    _nameController = TextEditingController();
    _departmentController = TextEditingController();
    _levelController = TextEditingController();
  }
  
  @override
  void didUpdateWidget(StudentProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when profile data changes
    _updateControllers();
  }
  
  void _updateControllers() {
    if (_viewModel.studentProfile != null) {
      _nameController.text = _viewModel.studentProfile!['name'] ?? '';
      _departmentController.text = _viewModel.studentProfile!['department'] ?? '';
      _levelController.text = _viewModel.studentProfile!['level'] ?? '';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          // Edit/Save button
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: 'Save changes',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _updateControllers();
                setState(() => _isEditing = true);
              },
              tooltip: 'Edit profile',
            ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<StudentViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.studentProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load profile',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchStudentProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with image
                Center(
                  child: Column(
                    children: [
                      _buildProfileImage(theme),
                      const SizedBox(height: 16),
                      if (!_isEditing) ...[
                        Text(
                          viewModel.studentProfile!['name'] ?? 'Student',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          viewModel.studentProfile!['email'] ?? 'No email',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Profile details
                _isEditing
                    ? _buildEditForm(theme)
                    : _buildProfileDetails(theme),
              ],
            ),
          );
        },
      ),
    );
  }
    Widget _buildProfileImage(ThemeData theme) {
    final profile = _viewModel.studentProfile!;
    
    return Stack(
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: profile['profileImageUrl'] != null
              ? NetworkImage(profile['profileImageUrl'])
              : null,
          child: profile['profileImageUrl'] == null
              ? Text(
                  (profile['name'] ?? 'Student').toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(''),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        if (_isEditing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt),
                color: theme.colorScheme.onPrimary,
                iconSize: 20,
                onPressed: () {
                  // Todo: Implement image upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile image upload coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
    Widget _buildProfileDetails(ThemeData theme) {
    final profile = _viewModel.studentProfile!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID Card
        _buildInfoCard(
          theme, 
          title: 'Student Information',
          icon: Icons.badge_outlined,
          children: [            _buildInfoRow(theme, 'Department', profile['department'] ?? 'Not set'),
            _buildInfoRow(theme, 'Level', profile['level'] ?? 'Not set'),
            _buildInfoRow(
              theme, 
              'Joined', 
              _formatDate(profile['joinDate'] ?? DateTime.now()),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Account Settings Card
        _buildInfoCard(
          theme, 
          title: 'Account Settings',
          icon: Icons.settings_outlined,
          children: [
            _buildActionRow(
              theme,
              'Change Password',
              Icons.lock_outline,
              onTap: () {
                // Todo: Implement change password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change password functionality coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildActionRow(
              theme,
              'Notification Settings',
              Icons.notifications_outlined,
              onTap: () {
                // Todo: Implement notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
    Widget _buildEditForm(ThemeData theme) {
    final profile = _viewModel.studentProfile!;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email field (read-only)
          TextFormField(
            initialValue: profile['email'] ?? 'No email',
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            readOnly: true,
            enabled: false,          ),
          const SizedBox(height: 16),
          
          // Department field
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Department',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your department';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Level field
          TextFormField(
            controller: _levelController,
            decoration: const InputDecoration(
              labelText: 'Level',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your level';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                  icon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionRow(
    ThemeData theme,
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
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
    );
  }
    void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = {
        'name': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'level': _levelController.text.trim(),
      };
      
      // Call ViewModel to update profile in Firestore
      _viewModel.updateStudentProfile(updatedProfile);
      
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
