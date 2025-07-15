// StudentViewModel for MVVM architecture
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'allocation_viewmodel.dart';
import 'dart:async';

class StudentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AllocationViewModel? _allocationViewModel;
  
  // Student topic data
  bool _isLoading = false;
  bool _hasAllocatedTopic = false;
  Map<String, dynamic>? _allocatedTopic;
  Map<String, dynamic>? _supervisorData;
  List<Map<String, dynamic>> _milestones = [];
  List<Map<String, dynamic>> _resources = [];
  
  // Student profile data
  Map<String, dynamic>? _studentProfile;
  bool _isProfileLoading = false;
  String? _profileError;
    // Student interests data
  List<String> _studentInterests = [];
  bool _isLoadingInterests = false;
  String? _interestsError;
  bool _interestsSaved = false; // Track if interests have been successfully saved
  
  // Enhanced data with pending requests
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _hasPendingRequests = false;
  
  String? _error;
  
  // Real-time subscription variables
  StreamSubscription<QuerySnapshot>? _allocationSubscription;
  StreamSubscription<QuerySnapshot>? _projectRequestsSubscription;
  StreamSubscription<QuerySnapshot>? _milestonesSubscription;
  StreamSubscription<QuerySnapshot>? _resourcesSubscription;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasAllocatedTopic => _hasAllocatedTopic;
  Map<String, dynamic>? get allocatedTopic => _allocatedTopic;
  Map<String, dynamic>? get supervisorData => _supervisorData;
  List<Map<String, dynamic>> get milestones => _milestones;
  List<Map<String, dynamic>> get resources => _resources;
  String? get error => _error;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Profile getters
  bool get isProfileLoading => _isProfileLoading;
  Map<String, dynamic>? get studentProfile => _studentProfile;
  String? get profileError => _profileError;
    // Interests getters
  List<String> get studentInterests => _studentInterests;
  bool get isLoadingInterests => _isLoadingInterests;
  String? get interestsError => _interestsError;
  bool get interestsSaved => _interestsSaved;
  
  // Pending requests getters
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  bool get hasPendingRequests => _hasPendingRequests;
  
  // Initialize and fetch data (with fallback to non-real-time)
  Future<void> fetchStudentTopicData() async {
    if (_auth.currentUser == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final studentId = _auth.currentUser!.uid;
      
      // Check for an allocation first
      final allocationSnapshot = await _firestore
          .collection('allocations')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      
      if (allocationSnapshot.docs.isEmpty) {
        // No topic allocated, check for pending requests
        await _checkForPendingRequests(studentId);
        _hasAllocatedTopic = false;
        _allocatedTopic = null;
        _supervisorData = null;
        _milestones = [];
        _resources = [];
      } else {
        // Topic is allocated
        _hasAllocatedTopic = true;
        final allocation = allocationSnapshot.docs.first.data();
        final topicId = allocation['topicId'];
        final lecturerId = allocation['lecturerId'];
        
        // Fetch topic details
        final topicSnapshot = await _firestore.collection('topics').doc(topicId).get();
        if (topicSnapshot.exists) {
          _allocatedTopic = {
            ...topicSnapshot.data()!,
            'id': topicId,
            'dateAllocated': allocation['dateAllocated'] ?? DateTime.now(),
            'status': allocation['status'] ?? 'Allocated',
          };
          
          // Fetch supervisor details
          final lecturerSnapshot = await _firestore.collection('users').doc(lecturerId).get();
          if (lecturerSnapshot.exists) {
            _supervisorData = {
              ...lecturerSnapshot.data()!,
              'id': lecturerId,
            };
          }
          
          // Fetch real milestones and resources
          await _fetchTopicMilestonesAndResources(topicId);
        }
      }
      
      // Try to start real-time updates (with error handling)
      try {
        startRealtimeAllocationUpdates();
      } catch (e) {
        print('Real-time updates not available: $e');
        // Continue without real-time updates
      }
      
    } catch (e) {
      _error = 'Failed to load topic data: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch student profile data
  Future<void> fetchStudentProfile() async {
    if (_auth.currentUser == null) return;
    
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();
    
    try {
      final studentId = _auth.currentUser!.uid;
      
      // Fetch student profile
      final profileSnapshot = await _firestore.collection('users').doc(studentId).get();
      if (profileSnapshot.exists) {
        _studentProfile = {
          ...profileSnapshot.data()!,
          'id': studentId,
        };
        
        // Ensure joinDate is a DateTime
        if (_studentProfile!['joinDate'] != null && _studentProfile!['joinDate'] is Timestamp) {
          _studentProfile!['joinDate'] = (_studentProfile!['joinDate'] as Timestamp).toDate();
        } else if (_studentProfile!['joinDate'] == null) {
          // Set default join date if not available
          _studentProfile!['joinDate'] = DateTime.now();
        }
      } else {
        // Create a default profile if none exists
        _studentProfile = {
          'id': studentId,
          'name': _auth.currentUser?.displayName ?? 'Student',
          'email': _auth.currentUser?.email ?? 'No email',
          'studentId': 'Not set',
          'department': 'Not set',
          'level': 'Not set',
          'gpa': 0.0,
          'joinDate': DateTime.now(),
        };
      }
    } catch (e) {
      _profileError = 'Failed to load profile data: ${e.toString()}';
      print(_profileError);
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }
  
  // Update student profile
  Future<void> updateStudentProfile(Map<String, dynamic> profileData) async {
    if (_auth.currentUser == null) return;
    
    _isProfileLoading = true;
    notifyListeners();
    
    try {
      final studentId = _auth.currentUser!.uid;
      
      // Update in Firestore
      await _firestore.collection('users').doc(studentId).update(profileData);
      
      // Update local state
      _studentProfile = {
        ...?_studentProfile,
        ...profileData,
      };
    } catch (e) {
      _profileError = 'Failed to update profile: ${e.toString()}';
      print(_profileError);
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }
    // Fetch student interests from Firestore
  Future<List<String>> fetchStudentInterests() async {
    if (_auth.currentUser == null) return [];
    
    _isLoadingInterests = true;
    _interestsError = null;
    notifyListeners();
    
    try {
      final studentId = _auth.currentUser!.uid;
      final interestsDoc = await _firestore.collection('users')
          .doc(studentId)
          .collection('interests')
          .doc('interests_data')
          .get();
      
      if (interestsDoc.exists) {
        final interests = List<String>.from(interestsDoc.data()?['interests'] ?? []);
        _studentInterests = interests;
        // Interests loaded from database are considered saved
        _interestsSaved = true;
        _isLoadingInterests = false;
        notifyListeners();
        return interests;
      }
      
      _interestsSaved = false; // No interests saved
      _isLoadingInterests = false;
      notifyListeners();
      return [];
      
    } catch (e) {
      _isLoadingInterests = false;
      _interestsError = e.toString();
      _interestsSaved = false;
      notifyListeners();
      return [];
    }
  }
  
  // Reset the saved status when interests are changed
  void markInterestsAsUnsaved() {
    if (_interestsSaved) {
      _interestsSaved = false;
      notifyListeners();
    }
  }
  // Save student interests to Firestore and calculate matches
  Future<Map<String, dynamic>> saveStudentInterests(List<String> interests) async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }
    
    _isLoadingInterests = true;
    _interestsError = null;
    _interestsSaved = false; // Reset saved status
    notifyListeners();
    
    try {
      final studentId = _auth.currentUser!.uid;
      await _firestore.collection('users')
          .doc(studentId)
          .collection('interests')
          .doc('interests_data')
          .set({
            'interests': interests,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      
      // Also save in the main interests collection for easier querying
      await _firestore.collection('interests')
          .doc(studentId)
          .set({
            'studentId': studentId,
            'interests': interests,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      
      _studentInterests = interests;
      _interestsSaved = true; // Mark as successfully saved
      
      // Calculate matches based on new interests
      Map<String, dynamic> matchResults = {};
      try {
        if (_allocationViewModel != null) {
          matchResults = await _allocationViewModel!.findComprehensiveMatches(studentId);
        }
      } catch (matchError) {
        // Don't fail the entire operation if matching fails
        print('Warning: Failed to calculate matches: $matchError');
      }
      
      _isLoadingInterests = false;
      notifyListeners();
      
      return matchResults;
      
    } catch (e) {
      _isLoadingInterests = false;
      _interestsError = e.toString();
      _interestsSaved = false; // Mark as not saved on error
      notifyListeners();
      throw e;
    }
  }
  
  // Fetch real milestones and resources from Firestore and start real-time listeners
  Future<void> _fetchTopicMilestonesAndResources(String topicId) async {
    try {
      // Fetch initial milestones
      final milestonesSnapshot = await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('milestones')
          .orderBy('dueDate')
          .get();
      
      _milestones = milestonesSnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime if needed
        if (data['dueDate'] is Timestamp) {
          data['dueDate'] = (data['dueDate'] as Timestamp).toDate();
        }
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
      
      // Fetch initial resources
      final resourcesSnapshot = await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('resources')
          .get();
      
      _resources = resourcesSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      
      // Start real-time listeners for milestones and resources
      _startRealtimeMilestonesListener(topicId);
      _startRealtimeResourcesListener(topicId);
      
    } catch (e) {
      print('Error fetching milestones and resources: $e');
      // If there's an error, initialize with empty lists
      _milestones = [];
      _resources = [];
    }
  }
  
  // Start real-time milestones listener
  void _startRealtimeMilestonesListener(String topicId) {
    _milestonesSubscription?.cancel();
    
    _milestonesSubscription = _firestore
        .collection('topics')
        .doc(topicId)
        .collection('milestones')
        .orderBy('dueDate')
        .snapshots()
        .listen(
      (snapshot) async {
        await Future.microtask(() {
          _milestones = snapshot.docs.map((doc) {
            final data = doc.data();
            // Convert Firestore Timestamp to DateTime if needed
            if (data['dueDate'] is Timestamp) {
              data['dueDate'] = (data['dueDate'] as Timestamp).toDate();
            }
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
          notifyListeners();
        });
      },
      onError: (error) {
        Future.microtask(() {
          print('Error listening to milestones: $error');
        });
      },
    );
  }
  
  // Start real-time resources listener
  void _startRealtimeResourcesListener(String topicId) {
    _resourcesSubscription?.cancel();
    
    _resourcesSubscription = _firestore
        .collection('topics')
        .doc(topicId)
        .collection('resources')
        .snapshots()
        .listen(
      (snapshot) async {
        await Future.microtask(() {
          _resources = snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList();
          notifyListeners();
        });
      },
      onError: (error) {
        Future.microtask(() {
          print('Error listening to resources: $error');
        });
      },
    );
  }
  
  // Toggle milestone completion status and update Firestore
  Future<void> toggleMilestoneCompletion(String milestoneId) async {
    final index = _milestones.indexWhere((m) => m['id'] == milestoneId);
    if (index != -1 && _allocatedTopic != null) {
      try {
        // Update local state first for immediate UI feedback
        final newCompletionStatus = !_milestones[index]['completed'];
        _milestones[index]['completed'] = newCompletionStatus;
        notifyListeners();
        
        // Update Firestore
        await _firestore
            .collection('topics')
            .doc(_allocatedTopic!['id'])
            .collection('milestones')
            .doc(milestoneId)
            .update({
          'completed': newCompletionStatus,
          'completedAt': newCompletionStatus ? FieldValue.serverTimestamp() : null,
        });
        
      } catch (e) {
        // Revert local state if Firestore update fails
        _milestones[index]['completed'] = !_milestones[index]['completed'];
        notifyListeners();
        print('Error updating milestone: $e');
        // You might want to show an error message to the user here
      }
    }
  }
  
  // Request meeting with supervisor
  Future<void> requestMeeting(String subject, String message) async {
    if (_auth.currentUser == null || _supervisorData == null) {
      throw Exception('User not logged in or no supervisor assigned');
    }
    
    try {
      // Create a meeting request in Firestore
      await _firestore.collection('meeting_requests').add({
        'studentId': _auth.currentUser!.uid,
        'studentName': _auth.currentUser?.displayName ?? 'Student',
        'lecturerId': _supervisorData!['id'],
        'topicId': _allocatedTopic?['id'],
        'subject': subject,
        'message': message,
        'status': 'pending',
        'dateRequested': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('Error creating meeting request: $e');
      throw Exception('Failed to send meeting request: ${e.toString()}');
    }
  }
  
  // Set allocation view model (called by main app during initialization)
  void setAllocationViewModel(AllocationViewModel viewModel) {
    _allocationViewModel = viewModel;
    // No need to notify listeners here as this is called during initialization
  }
  
  // Check if the allocation view model is set
  bool get hasAllocationViewModel => _allocationViewModel != null;
  
  // Check for pending project requests
  Future<void> _checkForPendingRequests(String studentId) async {
    try {
      // Check for pending requests in a requests collection
      // In a real app, this would check for submitted requests that haven't been approved
      final pendingSnapshot = await _firestore
          .collection('project_requests')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      _pendingRequests = pendingSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      
      _hasPendingRequests = _pendingRequests.isNotEmpty;
      
      // If there are pending requests, show them in the topic view as pending allocation
      if (_hasPendingRequests) {
        final firstRequest = _pendingRequests.first;
        
        // Fetch topic details for the pending request
        final topicSnapshot = await _firestore
            .collection('topics')
            .doc(firstRequest['topicId'])
            .get();
        
        if (topicSnapshot.exists) {
          final topicData = topicSnapshot.data()!;
          
          // Show as allocated but with pending status
          _hasAllocatedTopic = true;
          _allocatedTopic = {
            ...topicData,
            'id': firstRequest['topicId'],
            'dateRequested': firstRequest['dateRequested'] ?? DateTime.now(),
            'status': 'Pending Approval',
            'requestId': firstRequest['id'],
          };
          
          // Fetch lecturer details
          final lecturerSnapshot = await _firestore
              .collection('users')
              .doc(firstRequest['lecturerId'])
              .get();
          
          if (lecturerSnapshot.exists) {
            _supervisorData = {
              ...lecturerSnapshot.data()!,
              'id': firstRequest['lecturerId'],
            };
          }
        }
      }
    } catch (e) {
      print('Error checking pending requests: $e');
      _hasPendingRequests = false;
      _pendingRequests = [];
    }
  }
  
  // Cancel a pending project request
  Future<bool> cancelProjectRequest(String requestId) async {
    try {
      await _firestore.collection('project_requests').doc(requestId).delete();
      
      // Reset the topic data
      _hasAllocatedTopic = false;
      _allocatedTopic = null;
      _supervisorData = null;
      _hasPendingRequests = false;
      _pendingRequests = [];
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error canceling request: $e');
      return false;
    }
  }

  // Dispose method to clean up subscriptions
  @override
  void dispose() {
    _allocationSubscription?.cancel();
    _projectRequestsSubscription?.cancel();
    _milestonesSubscription?.cancel();
    _resourcesSubscription?.cancel();
    super.dispose();
  }

  // Start real-time allocation updates
  void startRealtimeAllocationUpdates() {
    final studentId = _auth.currentUser?.uid;
    if (studentId == null) return;
    
    _allocationSubscription?.cancel();
    
    _allocationSubscription = _firestore
        .collection('allocations')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .listen(
      (snapshot) async {
        // Use microtask to avoid setState during build
        await Future.microtask(() async {
          if (snapshot.docs.isEmpty) {
            // No allocation found, check for pending requests
            await _startRealtimeProjectRequestUpdates();
          } else {
            // Found allocation, fetch topic details
            final allocation = snapshot.docs.first.data();
            await _fetchTopicDetails(allocation);
          }
        });
      },
      onError: (error) {
        Future.microtask(() {
          _error = 'Failed to load allocation: $error';
          notifyListeners();
        });
      },
    );
  }

  // Start real-time project request updates
  Future<void> _startRealtimeProjectRequestUpdates() async {
    final studentId = _auth.currentUser?.uid;
    if (studentId == null) return;
    
    _projectRequestsSubscription?.cancel();
    
    _projectRequestsSubscription = _firestore
        .collection('project_requests')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) async {
        // Use microtask to avoid setState during build
        await Future.microtask(() async {
          if (snapshot.docs.isEmpty) {
            // No pending requests
            _hasAllocatedTopic = false;
            _allocatedTopic = null;
            _supervisorData = null;
            _hasPendingRequests = false;
            _pendingRequests = [];
          } else {
            // Found pending request
            final request = snapshot.docs.first.data();
            await _fetchPendingRequestDetails(request, snapshot.docs.first.id);
          }
          notifyListeners();
        });
      },
      onError: (error) {
        Future.microtask(() {
          _error = 'Failed to load project requests: $error';
          notifyListeners();
        });
      },
    );
  }

  // Fetch topic details for allocation
  Future<void> _fetchTopicDetails(Map<String, dynamic> allocation) async {
    try {
      final topicSnapshot = await _firestore
          .collection('topics')
          .doc(allocation['topicId'])
          .get();
      
      if (topicSnapshot.exists) {
        _hasAllocatedTopic = true;
        _allocatedTopic = {
          ...topicSnapshot.data()!,
          'id': allocation['topicId'],
          'dateAllocated': allocation['dateAllocated'],
          'status': allocation['status'] ?? 'Allocated',
        };
        
        // Fetch supervisor details
        final supervisorSnapshot = await _firestore
            .collection('users')
            .doc(allocation['lecturerId'])
            .get();
        
        if (supervisorSnapshot.exists) {
          _supervisorData = {
            ...supervisorSnapshot.data()!,
            'id': allocation['lecturerId'],
          };
        }
        
        // Fetch real milestones and resources
        await _fetchTopicMilestonesAndResources(allocation['topicId']);
        
        _hasPendingRequests = false;
        _pendingRequests = [];
      }
    } catch (e) {
      _error = 'Failed to load topic details: $e';
    }
  }

  // Fetch pending request details
  Future<void> _fetchPendingRequestDetails(Map<String, dynamic> request, String requestId) async {
    try {
      final topicSnapshot = await _firestore
          .collection('topics')
          .doc(request['topicId'])
          .get();
      
      if (topicSnapshot.exists) {
        _hasAllocatedTopic = true;
        _allocatedTopic = {
          ...topicSnapshot.data()!,
          'id': request['topicId'],
          'dateRequested': request['dateRequested'],
          'status': 'Pending Approval',
          'requestId': requestId,
        };
        
        // Fetch lecturer details
        final lecturerSnapshot = await _firestore
            .collection('users')
            .doc(request['lecturerId'])
            .get();
        
        if (lecturerSnapshot.exists) {
          _supervisorData = {
            ...lecturerSnapshot.data()!,
            'id': request['lecturerId'],
          };
        }
        
        _hasPendingRequests = true;
        _pendingRequests = [
          {
            ...request,
            'id': requestId,
            'topicTitle': topicSnapshot.data()?['title'] ?? 'Unknown Topic',
          }
        ];
      }
    } catch (e) {
      _error = 'Failed to load pending request details: $e';
    }
  }

  // Stop real-time updates
  void stopRealtimeUpdates() {
    _allocationSubscription?.cancel();
    _projectRequestsSubscription?.cancel();
    _milestonesSubscription?.cancel();
    _resourcesSubscription?.cancel();
  }

  // ...existing code...
}
