import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentMessagesScreen extends StatefulWidget {
  const StudentMessagesScreen({Key? key}) : super(key: key);

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  final TextEditingController _replyController = TextEditingController();
  String? _replyToLecturerId;
  String? _replyToLecturerName;
  bool _sending = false;
  String? _error;

  User? get _student => FirebaseAuth.instance.currentUser;

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (_replyToLecturerId != null && reply.isNotEmpty && _student != null) {
      setState(() {
        _sending = true;
        _error = null;
      });
      try {
        await FirebaseFirestore.instance.collection('messages').add({
          'senderId': _student!.uid,
          'senderName': _student!.displayName ?? 'Student',
          'recipientId': _replyToLecturerId,
          'recipientName': _replyToLecturerName,
          'message': reply,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _replyController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reply sent to $_replyToLecturerName!')),
        );
      } catch (e) {
        setState(() {
          _error = 'Failed to send reply: $e';
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
        title: const Text('Messages'),
      ),
      body: _student == null
          ? const Center(child: Text('Not authenticated'))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .where('recipientId', isEqualTo: _student!.uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: \\${snapshot.error}'));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet. When a lecturer sends you a message, it will appear here.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final msg = docs[index].data() as Map<String, dynamic>;
                            final isSelected = _replyToLecturerId == msg['senderId'];
                            return Card(
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text((msg['senderName'] ?? '?')[0]),
                                ),
                                title: Text(msg['senderName'] ?? ''),
                                subtitle: Text(msg['message'] ?? ''),
                                trailing: Text(
                                  msg['timestamp'] != null && msg['timestamp'] is Timestamp
                                      ? (msg['timestamp'] as Timestamp).toDate().toLocal().toString().substring(11, 16)
                                      : '',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                ),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _replyToLecturerId = msg['senderId'];
                                    _replyToLecturerName = msg['senderName'];
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_replyToLecturerId != null) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Reply to $_replyToLecturerName',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _replyController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Type your reply',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _replyController.text.trim().isEmpty || _sending
                                    ? null
                                    : _sendReply,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: const Text('Send Reply'),
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
                  ]
                ],
              ),
            ),
    );
  }
} 