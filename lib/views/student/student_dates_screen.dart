import 'package:flutter/material.dart';

class StudentDatesScreen extends StatelessWidget {
  const StudentDatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Dates'),
      ),
      body: const Center(
        child: Text(
          'Important Dates feature coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 