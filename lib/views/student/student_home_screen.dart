import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const StudentHomeScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
            const Text('Welcome, Student!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Select or Edit Interests'),
                subtitle: const Text('Choose your research interests.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // Todo: Implement navigation
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment_turned_in),
                title: const Text('View Allocated Topic'),
                subtitle: const Text('See your assigned project topic.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {}, // Todo: Implement navigation
              ),
            ),
          ],
        ),
      ),
    );
  }
}
