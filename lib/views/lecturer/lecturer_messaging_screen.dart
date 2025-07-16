import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LecturerMessagingScreen extends StatefulWidget {
  const LecturerMessagingScreen({Key? key}) : super(key: key);

  @override
  State<LecturerMessagingScreen> createState() => _LecturerMessagingScreenState();
}

class _LecturerMessagingScreenState extends State<LecturerMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedStudentUid;
  String? _selectedStudentName;
  bool _sending = false;
  String? _error;

  User? get _lecturer => FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (_selectedStudentUid != null && message.isNotEmpty && _lecturer != null) {
      setState(() {
        _sending = true;
        _error = null;
      });
      try {
        await FirebaseFirestore.instance.collection('messages').add({
          'senderId': _lecturer!.uid,
          'senderName': _lecturer!.displayName ?? 'Lecturer',
          'recipientId': _selectedStudentUid,
          'recipientName': _selectedStudentName,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _messageController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent to $_selectedStudentName!')),
        );
      } catch (e) {
        setState(() {
          _error = 'Failed to send message: $e';
        });
      } finally {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Students'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'student')
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading students: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error));
                        }
                        final students = snapshot.data?.docs ?? [];
                        if (students.isEmpty) {
                          return const Text('No students found.');
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedStudentUid,
                          items: students
                              .map((doc) => DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(doc['name'] ?? doc['email'] ?? 'Unknown'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            final student = students.firstWhere((s) => s.id == value);
                            setState(() {
                              _selectedStudentUid = value;
                              _selectedStudentName = student['name'] ?? student['email'] ?? 'Unknown';
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Student',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Type your message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedStudentUid == null || _messageController.text.trim().isEmpty || _sending
                            ? null
                            : _sendMessage,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sent Messages',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _lecturer == null
                  ? Center(child: Text('Not authenticated'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .where('senderId', isEqualTo: _lecturer!.uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages sent yet.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final msg = docs[index].data() as Map<String, dynamic>;
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text((msg['recipientName'] ?? '?')[0]),
                                ),
                                title: Text(msg['recipientName'] ?? ''),
                                subtitle: Text(msg['message'] ?? ''),
                                trailing: Text(
                                  msg['timestamp'] != null && msg['timestamp'] is Timestamp
                                      ? (msg['timestamp'] as Timestamp).toDate().toLocal().toString().substring(11, 16)
                                      : '',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 