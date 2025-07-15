import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const AdminHomeScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            const Text('Welcome, Admin!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.topic),
                title: const Text('Manage All Topics'),
                subtitle: const Text('View and manage all project topics.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // todo: Implement navigation
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Trigger Allocation'),
                subtitle: const Text('Run the topic allocation algorithm.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // todo: Implement navigation
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('System Stats'),
                subtitle: const Text('View allocation and user statistics.'),
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
