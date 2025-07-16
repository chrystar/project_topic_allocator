import 'package:flutter/material.dart';

class StudentGuidelinesScreen extends StatelessWidget {
  const StudentGuidelinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Guidelines'),
      ),
      body: const Center(
        child: Text(
          'Project Guidelines feature coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 