import 'package:flutter/material.dart';

class StudentMessagesScreen extends StatelessWidget {
  const StudentMessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: const Center(
        child: Text(
          'Messages feature coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 