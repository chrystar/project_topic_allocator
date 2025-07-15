import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  String? _role; // 'student', 'lecturer', 'admin'
  User? _firebaseUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  String? get role => _role;
  User? get firebaseUser => _firebaseUser;

  AppState(); // No authStateChanges listener

  Future<void> checkAuthState() async {
    // Allow the splash screen to show for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      _firebaseUser = cred.user;
      _isAuthenticated = true;
      _role = await _fetchUserRole(_firebaseUser!.uid);
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _firebaseUser = null;
      _role = null;
      _isInitializing = false;
      notifyListeners();
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
      _firebaseUser = cred.user;
      _isAuthenticated = true;
      _role = role;
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _firebaseUser = null;
      _role = null;
      _isInitializing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    _firebaseUser = null;
    _role = null;
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> _saveUserRole(String uid, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
  }
  Future<String?> _fetchUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists ? (doc.data()?['role'] as String?) : 'student';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'student'; // Default to student role on error
    }
  }
}
