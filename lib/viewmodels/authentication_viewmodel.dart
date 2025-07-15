import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isAuthenticated = false;
  User? _user;
  String? _role;
  bool _isLoading = false;
  String? _error;
  
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthenticationViewModel() {
    _initialize();
  }
  
  void _initialize() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        _isAuthenticated = true;
        await _fetchUserRole();
      } else {
        _isAuthenticated = false;
        _role = null;
      }
      notifyListeners();
    });
  }
  
  Future<void> _fetchUserRole() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      _role = doc.data()?['role'] as String?;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Send email verification
      await userCredential.user?.sendEmailVerification();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  String _friendlyError(dynamic e) {
    final String errorMessage = e.toString();
    
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Please login or use a different email.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email format. Please enter a valid email address.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later or reset your password.';
    } else {
      return 'An error occurred. Please try again later.';
    }
  }
  
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _friendlyError(e);
      notifyListeners();
    }
  }
}
