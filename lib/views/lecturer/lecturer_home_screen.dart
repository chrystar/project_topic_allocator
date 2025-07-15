import 'package:flutter/material.dart';

class LecturerHomeScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const LecturerHomeScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome, Lecturer!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Specializations'),
                subtitle: const Text('Update your research areas.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // todo: Implement navigation
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.topic),
                title: const Text('Manage Topics'),
                subtitle: const Text('Add or edit project topics.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // todo: Implement navigation
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.group),
                title: const Text('View Assigned Students'),
                subtitle: const Text('See students assigned to your topics.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // todo: Implement navigation
              ),
            ),
          ],
        ),
      ),
    );
  }
}
