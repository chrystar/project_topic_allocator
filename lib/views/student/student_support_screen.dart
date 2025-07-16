import 'package:flutter/material.dart';

class StudentSupportScreen extends StatelessWidget {
  const StudentSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: const Center(
        child: Text(
          'Support feature coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 