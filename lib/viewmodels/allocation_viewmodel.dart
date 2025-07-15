// AllocationViewModel for MVVM architecture
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'matching_algorithm.dart';
import 'lecturer_viewmodel.dart';

class AllocationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchingAlgorithm _matchingAlgorithm = MatchingAlgorithm();
  
  bool _isLoading = false;
  String? _error;
  
  // Allocation data
  List<Map<String, dynamic>> _potentialMatches = [];
  List<Map<String, dynamic>> _allocations = [];
  
  // Enhanced matching data
  Map<String, dynamic>? _matchResults;
  
  // Stream subscription for lecturer specialization changes
  StreamSubscription? _specializationChangeSubscription;
  StreamSubscription? _recommendationsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get potentialMatches => _potentialMatches;
  List<Map<String, dynamic>> get allocations => _allocations;
  Map<String, dynamic>? get matchResults => _matchResults;
  
  // Find potential matches for a student based on their interests
  Future<List<Map<String, dynamic>>> findMatchingLecturers(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get student interests
      final studentInterestsDoc = await _firestore
          .collection('interests')
          .doc(studentId)
          .get();
      
      if (!studentInterestsDoc.exists) {
        _isLoading = false;
        _error = 'Student interests not found';
        notifyListeners();
        return [];
      }
      
      final studentInterests = List<String>.from(
          studentInterestsDoc.data()?['interests'] ?? []);
      
      if (studentInterests.isEmpty) {
        _isLoading = false;
        _error = 'Student has not selected any interests';
        notifyListeners();
        return [];
      }
      
      // Get all lecturers with their specializations
      final lecturersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'lecturer')
          .get();
      
      final List<Map<String, dynamic>> matchingLecturers = [];
      
      // For each lecturer, calculate a match score based on specializations
      for (var lecturerDoc in lecturersQuery.docs) {
        final lecturerId = lecturerDoc.id;
        final lecturer = lecturerDoc.data();
        
        // Get lecturer specializations
        final specializationsQuery = await _firestore
            .collection('users')
            .doc(lecturerId)
            .collection('specializations')
            .get();
        
        final List<String> lecturerSpecializations = [];
        for (var specDoc in specializationsQuery.docs) {
          final area = specDoc.data()['area'] as String?;
          if (area != null) lecturerSpecializations.add(area);
        }
        
        // Calculate match score: Number of matching interests/specializations
        int matchScore = 0;
        final List<String> matchingAreas = [];
        
        for (var interest in studentInterests) {
          if (lecturerSpecializations.contains(interest)) {
            matchScore++;
            matchingAreas.add(interest);
          }
        }
        
        // Only include if there's at least one match
        if (matchScore > 0) {
          matchingLecturers.add({
            'id': lecturerId,
            'name': lecturer['name'] ?? 'Unknown',
            'department': lecturer['department'] ?? 'Unknown',
            'email': lecturer['email'] ?? '',
            'matchScore': matchScore,
            'matchPercentage': (matchScore / studentInterests.length) * 100,
            'matchingAreas': matchingAreas,
            'specializations': lecturerSpecializations,
          });
        }
      }
      
      // Sort by match score (highest first)
      matchingLecturers.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
      
      _potentialMatches = matchingLecturers;
      _isLoading = false;
      notifyListeners();
      return matchingLecturers;
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // Find potential projects for a student based on their interests
  Future<List<Map<String, dynamic>>> findMatchingProjects(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get student interests
      final studentInterestsDoc = await _firestore
          .collection('interests')
          .doc(studentId)
          .get();
      
      if (!studentInterestsDoc.exists) {
        _isLoading = false;
        _error = 'Student interests not found';
        notifyListeners();
        return [];
      }
      
      final studentInterests = List<String>.from(
          studentInterestsDoc.data()?['interests'] ?? []);
      
      if (studentInterests.isEmpty) {
        _isLoading = false;
        _error = 'Student has not selected any interests';
        notifyListeners();
        return [];
      }
      
      // Get all available topics
      final topicsQuery = await _firestore
          .collection('topics')
          .where('isAllocated', isEqualTo: false)
          .get();
      
      final List<Map<String, dynamic>> matchingProjects = [];
      
      // For each topic, calculate a match score based on technologies/interests
      for (var topicDoc in topicsQuery.docs) {
        final topicId = topicDoc.id;
        final topic = topicDoc.data();
        
        // Get topic technologies/areas
        final List<String> topicTechnologies = 
            List<String>.from(topic['technologies'] ?? []);
        final List<String> topicAreas = 
            List<String>.from(topic['areas'] ?? []);
        
        // All areas of interest for the topic
        final List<String> allTopicAreas = [...topicTechnologies, ...topicAreas];
        
        // Calculate match score
        int matchScore = 0;
        final List<String> matchingAreas = [];
        
        for (var interest in studentInterests) {
          if (allTopicAreas.contains(interest)) {
            matchScore++;
            matchingAreas.add(interest);
          }
        }
        
        // Get lecturer details
        final lecturerId = topic['lecturerId'];
        final lecturerDoc = await _firestore.collection('users').doc(lecturerId).get();
        final lecturer = lecturerDoc.data() ?? {};
        
        // Only include if there's at least one match
        if (matchScore > 0) {
          matchingProjects.add({
            'id': topicId,
            'title': topic['title'] ?? 'Unknown',
            'description': topic['description'] ?? '',
            'lecturer': {
              'id': lecturerId,
              'name': lecturer['name'] ?? 'Unknown',
              'email': lecturer['email'] ?? '',
            },
            'matchScore': matchScore,
            'matchPercentage': (matchScore / studentInterests.length) * 100,
            'matchingAreas': matchingAreas,
            'technologies': topicTechnologies,
            'areas': topicAreas,
          });
        }
      }
      
      // Sort by match score (highest first)
      matchingProjects.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
      
      _isLoading = false;
      notifyListeners();
      return matchingProjects;
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
    // Allocate a project to a student
  Future<bool> allocateProjectToStudent({
    required String studentId, 
    required String topicId, 
    required String lecturerId
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Add timeout to prevent hanging
      return await Future.any([
        _createProjectRequest(studentId, topicId, lecturerId),
        Future.delayed(const Duration(seconds: 30), () {
          _error = 'Request timed out. Please try again.';
          notifyListeners();
          throw TimeoutException('Request timed out after 30 seconds');
        }),
      ]);
    } catch (e) {
      _isLoading = false;
      if (e is TimeoutException) {
        _error = 'Request timed out. Please try again.';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> _createProjectRequest(String studentId, String topicId, String lecturerId) async {
    try {
      // Check if student already has a pending request for this topic
      final existingRequestQuery = await _firestore
          .collection('project_requests')
          .where('studentId', isEqualTo: studentId)
          .where('topicId', isEqualTo: topicId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingRequestQuery.docs.isNotEmpty) {
        _isLoading = false;
        _error = 'You have already requested this project';
        notifyListeners();
        return false;
      }
      
      // Check if student already has an allocation or pending request
      final existingAllocationQuery = await _firestore
          .collection('allocations')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      if (existingAllocationQuery.docs.isNotEmpty) {
        _isLoading = false;
        _error = 'Student already has a project allocated';
        notifyListeners();
        return false;
      }
      
      // Create project request instead of immediate allocation
      final requestRef = _firestore.collection('project_requests').doc();
      
      await requestRef.set({
        'studentId': studentId,
        'topicId': topicId,
        'lecturerId': lecturerId,
        'dateRequested': FieldValue.serverTimestamp(),
        'status': 'pending',
        'requestMessage': 'Student requested this project based on interest match',
      });      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get all allocations (for admin view)
  Future<void> fetchAllAllocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final allocationsQuery = await _firestore
          .collection('allocations')
          .get();
      
      final List<Map<String, dynamic>> allocationsList = [];
      
      for (var allocDoc in allocationsQuery.docs) {
        final allocation = allocDoc.data();
        final studentId = allocation['studentId'];
        final topicId = allocation['topicId'];
        final lecturerId = allocation['lecturerId'];
        
        // Get student details
        final studentDoc = await _firestore.collection('users').doc(studentId).get();
        final student = studentDoc.data() ?? {};
        
        // Get topic details
        final topicDoc = await _firestore.collection('topics').doc(topicId).get();
        final topic = topicDoc.data() ?? {};
        
        // Get lecturer details
        final lecturerDoc = await _firestore.collection('users').doc(lecturerId).get();
        final lecturer = lecturerDoc.data() ?? {};
        
        allocationsList.add({
          'id': allocDoc.id,
          'status': allocation['status'] ?? 'Allocated',
          'dateAllocated': allocation['dateAllocated'],
          'student': {
            'id': studentId,
            'name': student['name'] ?? 'Unknown',
            'email': student['email'] ?? '',
          },
          'topic': {
            'id': topicId,
            'title': topic['title'] ?? 'Unknown',
          },
          'lecturer': {
            'id': lecturerId,
            'name': lecturer['name'] ?? 'Unknown',
            'email': lecturer['email'] ?? '',
          },
        });
      }
      
      _allocations = allocationsList;
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Use the enhanced matching algorithm to find both matching projects and lecturers
  Future<Map<String, dynamic>> findComprehensiveMatches(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use the matching algorithm to find all potential matches
      final results = await _matchingAlgorithm.findMatchesForStudent(
        studentId: studentId,
        includeDetailedScores: true,
      );
      
      _matchResults = results;
      _isLoading = false;
      notifyListeners();
      return results;
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {
        'projects': <Map<String, dynamic>>[],
        'lecturers': <Map<String, dynamic>>[],
        'error': e.toString(),
      };
    }
  }

  // Initialize real-time updates
  void initializeRealtimeUpdates(String studentId, LecturerViewModel lecturerViewModel) {
    // Listen for lecturer specialization changes
    _specializationChangeSubscription?.cancel();
    _specializationChangeSubscription = lecturerViewModel.onSpecializationChange.listen((lecturerId) async {
      await _matchingAlgorithm.recalculateMatchesForLecturerChange(lecturerId);
    });

    // Listen for recommendation updates
    _recommendationsSubscription?.cancel();
    _recommendationsSubscription = _matchingAlgorithm.getRealtimeRecommendations(studentId).listen((data) {
      if (data.containsKey('matches')) {
        _matchResults = data['matches'];
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _specializationChangeSubscription?.cancel();
    _recommendationsSubscription?.cancel();
    super.dispose();
  }
}
