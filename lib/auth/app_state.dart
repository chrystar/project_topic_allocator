import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _role; // 'student', 'lecturer', 'admin'
  User? _firebaseUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  User? get firebaseUser => _firebaseUser;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        _isAuthenticated = true;
        _role = await _fetchUserRole(user.uid);
      } else {
        _isAuthenticated = false;
        _role = null;
      }
      notifyListeners();
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password, String role) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      await _saveUserRole(cred.user!.uid, role);
      // Store user profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _saveUserRole(String uid, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
  }

  Future<String?> _fetchUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
}
