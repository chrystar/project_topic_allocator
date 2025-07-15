import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/milestone.dart';
import 'dart:async';

class MilestoneViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String? _error;
  List<Milestone> _milestones = [];
  
  // Real-time updates
  StreamSubscription<QuerySnapshot>? _milestonesSubscription;
  String? _currentTopicId;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Milestone> get milestones => _milestones;
  
  // Dispose method to clean up subscriptions
  @override
  void dispose() {
    _milestonesSubscription?.cancel();
    super.dispose();
  }

  // Get overall project progress based on completed milestones
  double getProjectProgress() {
    if (_milestones.isEmpty) return 0.0;
    
    int totalWeight = _milestones.fold(0, (sum, m) => sum + m.weightage);
    if (totalWeight == 0) return 0.0;
    
    int completedWeight = _milestones
        .where((m) => m.isCompleted)
        .fold(0, (sum, m) => sum + m.weightage);
        
    return completedWeight / totalWeight;
  }

  // Start real-time milestone updates
  void startRealtimeMilestoneUpdates(String topicId) {
    // Cancel existing subscription if any
    _milestonesSubscription?.cancel();
    
    _currentTopicId = topicId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    _milestonesSubscription = _firestore
        .collection('topics')
        .doc(topicId)
        .collection('milestones')
        .orderBy('dueDate')
        .snapshots()
        .listen(
      (snapshot) {
        // Use microtask to avoid setState during build
        Future.microtask(() {
          try {
            _milestones = snapshot.docs
                .map((doc) => Milestone.fromMap(doc.id, doc.data()))
                .toList();
            
            _isLoading = false;
            _error = null;
            notifyListeners();
          } catch (e) {
            _error = 'Failed to load milestones: $e';
            _isLoading = false;
            notifyListeners();
          }
        });
      },
      onError: (error) {
        Future.microtask(() {
          _error = 'Failed to load milestones: $error';
          _isLoading = false;
          notifyListeners();
        });
      },
    );
  }

  // Stop real-time updates
  void stopRealtimeMilestoneUpdates() {
    _milestonesSubscription?.cancel();
    _milestonesSubscription = null;
    _currentTopicId = null;
  }

  // Fetch milestones for a specific project (now uses real-time updates)
  Future<void> fetchMilestones(String topicId) async {
    // If we're already listening to this topic, don't start again
    if (_currentTopicId == topicId && _milestonesSubscription != null) {
      return;
    }
    
    startRealtimeMilestoneUpdates(topicId);
  }
  
  // Add a new milestone
  Future<void> addMilestone(String topicId, Milestone milestone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('milestones')
          .add(milestone.toMap());
          
      await fetchMilestones(topicId);
    } catch (e) {
      _error = 'Failed to add milestone: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  // Update milestone status  
  Future<void> updateMilestoneStatus(
    String topicId, 
    String milestoneId,
    bool isCompleted, {
    String? feedback,
  }) async {
    try {
      // Create an optimistic update first
      final milestone = _milestones.firstWhere((m) => m.id == milestoneId);
      final updatedMilestone = milestone.copyWith(
        isCompleted: isCompleted,
        completedDate: isCompleted ? DateTime.now() : null,
        feedback: feedback,
      );

      // Update local state immediately (optimistically)
      final index = _milestones.indexWhere((m) => m.id == milestoneId);
      if (index != -1) {
        _milestones = List.from(_milestones)
          ..[index] = updatedMilestone;
        notifyListeners();
      }

      // Then update Firestore
      await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('milestones')
          .doc(milestoneId)
          .update({
        'isCompleted': isCompleted,
        'completedDate': isCompleted ? FieldValue.serverTimestamp() : null,
        if (feedback != null) 'feedback': feedback,
      });

      // No need to fetch milestones again since we already updated locally
    } catch (e) {
      // Revert optimistic update on error
      await fetchMilestones(topicId);
      _error = 'Failed to update milestone: $e';
      notifyListeners();
      throw e; // Re-throw to allow UI to show error
    }
  }
  
  // Edit milestone details
  Future<void> editMilestone(
    String topicId,
    String milestoneId,
    Milestone milestone,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('milestones')
          .doc(milestoneId)
          .update(milestone.toMap());
          
      await fetchMilestones(topicId);
    } catch (e) {
      _error = 'Failed to edit milestone: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete milestone
  Future<void> deleteMilestone(String topicId, String milestoneId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('milestones')
          .doc(milestoneId)
          .delete();
          
      await fetchMilestones(topicId);
    } catch (e) {
      _error = 'Failed to delete milestone: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
