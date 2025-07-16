import 'package:flutter/material.dart';

class LecturerProgressScreen extends StatelessWidget {
  const LecturerProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress Tracking'),
      ),
      body: const Center(
        child: Text(
          'Student Progress Tracking feature coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 