// filepath: d:\flutter projects\project_topic_allocator\lib\viewmodels\lecturer_viewmodel.dart
// LecturerViewModel for MVVM architecture
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LecturerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Lecturer profile data
  bool _isLoading = false;
  Map<String, dynamic>? _lecturerProfile;
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _specializations = [];
  List<Map<String, dynamic>> _assignedStudents = [];
  List<Map<String, dynamic>> _pendingAllocations = [];
  List<Map<String, dynamic>> _allLecturers = []; // New property
  String? _error;
  
  // Real-time subscription variables
  StreamSubscription<QuerySnapshot>? _projectRequestsSubscription;
  StreamSubscription<QuerySnapshot>? _allocationsSubscription;
  
  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lecturerProfile => _lecturerProfile;
  List<Map<String, dynamic>> get topics => _topics;
  List<Map<String, dynamic>> get specializations => _specializations;
  List<Map<String, dynamic>> get assignedStudents => _assignedStudents;
  List<Map<String, dynamic>> get pendingAllocations => _pendingAllocations;
  List<Map<String, dynamic>> get allLecturers => _allLecturers; // New getter
  String? get error => _error;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Stream controller for specialization changes
  final StreamController<String> _specializationChangeController = StreamController<String>.broadcast();
  Stream<String> get onSpecializationChange => _specializationChangeController.stream;

  // Initialize and fetch data
  Future<void> fetchLecturerData() async {
    if (_auth.currentUser == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final lecturerId = _auth.currentUser!.uid;
      
      // Fetch lecturer profile
      final profileSnapshot = await _firestore.collection('users').doc(lecturerId).get();
      if (profileSnapshot.exists) {
        _lecturerProfile = {
          ...profileSnapshot.data()!,
          'id': lecturerId,
        };
      } else {
        _lecturerProfile = null;
      }
      
      // Fetch specializations
      final specializationsSnapshot = await _firestore
          .collection('users')
          .doc(lecturerId)
          .collection('specializations')
          .get();
      
      _specializations = specializationsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      // Fetch topics
      final topicsSnapshot = await _firestore
          .collection('topics')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();

      _topics = topicsSnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime if needed
        if (data['dateCreated'] is Timestamp) {
          data['dateCreated'] = data['dateCreated'];  // Keep as Timestamp for consistency
        }
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
      
      // Fetch assigned students (via allocations)
      final allocationsSnapshot = await _firestore
          .collection('allocations')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();
      
      final allocations = allocationsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();      // Get student details for each allocation
      _assignedStudents = [];
      final uniqueAllocations = <String, Map<String, dynamic>>{};  // Map by studentId to prevent duplicates
      
      for (var allocation in allocations) {
        final studentId = allocation['studentId'];
        // Skip if we already have this student's allocation
        if (uniqueAllocations.containsKey(studentId)) continue;
        
        final studentSnapshot = await _firestore.collection('users').doc(studentId).get();
        if (studentSnapshot.exists) {
          // Convert Timestamp to DateTime if needed
          dynamic allocationDate = allocation['dateAllocated'];
          if (allocationDate is Timestamp) {
            allocationDate = allocationDate.toDate();
          }
          
          uniqueAllocations[studentId] = {
            ...studentSnapshot.data()!,
            'id': studentId,
            'topicId': allocation['topicId'],
            'allocationId': allocation['id'],
            'allocationDate': allocationDate,
          };
        }
      }
      
      // Set _assignedStudents to the values from uniqueAllocations
      _assignedStudents = uniqueAllocations.values.toList();
      
      // Get pending allocations (student interests)
      final pendingSnapshot = await _firestore
          .collection('interests')
          .where('lecturerTopics', arrayContains: lecturerId)
          .get();
      _pendingAllocations = pendingSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
      
    } catch (e) {
      _error = 'Failed to load lecturer data:  [31m${e.toString()} [0m';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Fetch lecturer specializations from Firestore
  Future<List<String>> fetchLecturerSpecializations() async {
    if (_auth.currentUser == null) {
      _error = 'User not logged in';
      notifyListeners();
      return [];
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final lecturerId = _auth.currentUser?.uid;
      if (lecturerId == null || lecturerId.isEmpty) {
        _error = 'Invalid user ID';
        _isLoading = false;
        notifyListeners();
        return [];
      }
        // Specializations are stored in a subcollection under the user document
      final specializationsSnapshot = await _firestore
          .collection('users')
          .doc(lecturerId)
          .collection('specializations')
          .doc('specialization_data')
          .get();
      
      if (specializationsSnapshot.exists && specializationsSnapshot.data() != null) {
        final data = specializationsSnapshot.data()!;
        final areasData = data['areas'];
        
        if (areasData is List) {
          final specializations = areasData.map((item) => item.toString()).toList();
          _isLoading = false;
          notifyListeners();
          return specializations;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return [];
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
    // Save lecturer specializations to Firestore
  Future<void> saveLecturerSpecializations(List<String> specializations) async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final lecturerId = _auth.currentUser?.uid;
      if (lecturerId == null || lecturerId.isEmpty) {
        throw Exception('Invalid user ID. Please try logging in again.');
      }
      
      // Save to specializations subcollection
      await _firestore.collection('users')
          .doc(lecturerId)
          .collection('specializations')
          .doc('specialization_data')
          .set({
            'areas': specializations,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      
      // Also save in a separate specializations collection for easier querying
      await _firestore.collection('specializations')
          .doc(lecturerId)
          .set({
            'lecturerId': lecturerId,
            'areas': specializations,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      
      // Update local data
      _specializations = specializations.map((area) => {
        'area': area,
        'id': area.toLowerCase().replaceAll(' ', '_'),
      }).toList();
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }
    // Topic management methods
  Future<void> addTopic(String title, String description, int maxStudents, List<String> specializations, {List<String>? technologies, List<String>? areas}) async {
    try {
      _isLoading = true;
      notifyListeners();
        final now = DateTime.now();
      final topic = {
        'title': title,
        'description': description,
        'maxStudents': maxStudents,
        'specializations': specializations,
        'technologies': technologies ?? [],
        'areas': areas ?? [],
        'lecturerId': _auth.currentUser!.uid,
        'dateCreated': FieldValue.serverTimestamp(),
        'status': 'Active',
        'assignedCount': 0,
        'isAllocated': false,
      };
      
      // Save to Firebase
      final docRef = await _firestore.collection('topics').add(topic);
      
      // Add to local list with the Firestore document ID and current DateTime for display
      _topics.add({
        'title': title,
        'description': description,
        'maxStudents': maxStudents,
        'specializations': specializations,
        'technologies': technologies ?? [],
        'areas': areas ?? [],
        'lecturerId': _auth.currentUser!.uid,
        'dateCreated': Timestamp.fromDate(now), // Store as Timestamp for consistency
        'status': 'Active',
        'assignedCount': 0,
        'isAllocated': false,
        'id': docRef.id,
      });
    } catch (e) {
      _error = 'Failed to add topic: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
    Future<void> updateTopic(String id, String title, String description, int maxStudents, List<String> specializations, {List<String>? technologies, List<String>? areas}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update Firebase
      await _firestore.collection('topics').doc(id).update({
        'title': title,
        'description': description,
        'maxStudents': maxStudents,
        'specializations': specializations,
        'technologies': technologies ?? [],
        'areas': areas ?? [],
      });
      
      // Update local list
      final index = _topics.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _topics[index] = {
          ..._topics[index],
          'title': title,
          'description': description,
          'maxStudents': maxStudents,
          'specializations': specializations,
          'technologies': technologies ?? [],
          'areas': areas ?? [],
        };
      }
    } catch (e) {
      _error = 'Failed to update topic: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> removeTopic(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
        // Check if the topic has assigned students
      final hasAssignedStudents = _assignedStudents.any((s) => s['topicId'] == id);
      if (hasAssignedStudents) {
        throw Exception('Cannot delete a topic with assigned students');
      }
      
      // Delete from Firebase
      await _firestore.collection('topics').doc(id).delete();
      
      // Remove from local list
      _topics.removeWhere((t) => t['id'] == id);
    } catch (e) {
      _error = 'Failed to remove topic: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
    // Specialization management
  Future<void> addSpecialization(String name, String description, String level) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final specialization = {
        'name': name,
        'description': description,
        'level': level,
        'dateAdded': FieldValue.serverTimestamp(),
      };
      
      // Save to Firebase
      final docRef = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('specializations')
        .add(specialization);
      
      // Add to local list
      _specializations.add({
        ...specialization,
        'id': docRef.id,
        'dateAdded': DateTime.now(), // Use current time for local display
      });
    } catch (e) {
      _error = 'Failed to add specialization: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateSpecialization(String id, String name, String description, String level) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final updatedData = {
        'name': name,
        'description': description,
        'level': level,
        'dateUpdated': FieldValue.serverTimestamp(),
      };
      
      // Update Firebase
      await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('specializations')
        .doc(id)
        .update(updatedData);
      
      // Update local list
      final index = _specializations.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _specializations[index] = {
          ..._specializations[index],
          ...updatedData,
          'dateUpdated': DateTime.now(), // Use current time for local display
        };
      }
    } catch (e) {
      _error = 'Failed to update specialization: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> removeSpecialization(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Delete from Firebase
      await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('specializations')
        .doc(id)
        .delete();
      
      // Remove from local list
      _specializations.removeWhere((s) => s['id'] == id);
    } catch (e) {
      _error = 'Failed to remove specialization: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // For UI compatibility, alias for removeSpecialization
  Future<void> deleteSpecialization(String id) async {
    return removeSpecialization(id);
  }
  
  // Update lecturer profile
  Future<void> updateProfile(
    String name,
    String title,
    String department,
    String office,
    String officeHours,
    String bio,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final profileData = {
        'name': name,
        'title': title,
        'department': department,
        'office': office,
        'officeHours': officeHours,
        'bio': bio,
      };
      
      // In a real app, update Firebase
      // await _firestore.collection('users').doc(_auth.currentUser!.uid).update(profileData);
      
      // For mock data, update local profile
      if (_lecturerProfile != null) {
        _lecturerProfile = {
          ..._lecturerProfile!,
          ...profileData,
        };
      }
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Student allocation methods
  Future<void> allocateStudent(String studentId, String topicId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final lecturerId = _auth.currentUser?.uid;
      if (lecturerId == null) throw Exception('Not authenticated');

      // Fetch topic to get current assignedCount and maxStudents
      final topicRef = _firestore.collection('topics').doc(topicId);
      final topicSnapshot = await topicRef.get();
      if (!topicSnapshot.exists) throw Exception('Topic not found');
      final topicData = topicSnapshot.data()!;
      final int assignedCount = (topicData['assignedCount'] ?? 0) as int;
      final int maxStudents = (topicData['maxStudents'] ?? 1) as int;

      if (assignedCount >= maxStudents) {
        throw Exception('Topic has reached maximum number of students');
      }

      // Create allocation in Firestore
      final allocationRef = _firestore.collection('allocations').doc();
      await allocationRef.set({
        'studentId': studentId,
        'topicId': topicId,
        'lecturerId': lecturerId,
        'dateAllocated': FieldValue.serverTimestamp(),
        'status': 'Allocated',
      });

      // Update topic's assignedCount and allocation status
      await topicRef.update({
        'assignedCount': assignedCount + 1,
        if (assignedCount + 1 >= maxStudents) ...{
          'isAllocated': true,
        },
        'allocatedTo': FieldValue.arrayUnion([studentId]),
      });

      // Optionally: Remove from pending allocations in Firestore if tracked
      // (Assuming pending allocations are tracked in a collection, e.g., 'project_requests')
      // You may want to implement this if needed.

      // Refresh local data
      await fetchLecturerData();
    } catch (e) {
      _error = 'Failed to allocate student:  [31m${e.toString()} [0m';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update specializations and notify listeners
  Future<void> updateSpecializations(List<String> specializations) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Update specializations in Firestore
      await _firestore.collection('users').doc(userId).update({
        'specializations': specializations,
      });

      // Notify listeners about the change
      _specializationChangeController.add(userId);
      notifyListeners();
    } catch (e) {
      print('Error updating specializations: $e');
      rethrow;
    }
  }
  // Project requests handling
  List<Map<String, dynamic>> _projectRequests = [];
  List<Map<String, dynamic>> get projectRequests => _projectRequests;
  
  // Fetch pending project requests for this lecturer (now uses real-time updates)
  Future<void> fetchProjectRequests() async {
    startRealtimeProjectRequestUpdates();
  }
  
  // Approve a project request
  Future<bool> approveProjectRequest(String requestId, String studentId, String topicId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create allocation
      final allocationRef = _firestore.collection('allocations').doc();
      await allocationRef.set({
        'studentId': studentId,
        'topicId': topicId,
        'lecturerId': _auth.currentUser!.uid,
        'dateAllocated': FieldValue.serverTimestamp(),
        'status': 'Allocated',
      });
      
      // Update topic as allocated
      await _firestore.collection('topics').doc(topicId).update({
        'isAllocated': true,
        'allocatedTo': FieldValue.arrayUnion([studentId]),
      });
      
      // Update request status
      await _firestore.collection('project_requests').doc(requestId).update({
        'status': 'approved',
        'dateApproved': FieldValue.serverTimestamp(),
      });
        // Remove from local pending requests
      _projectRequests.removeWhere((request) => request['id'] == requestId);
      
      // Refresh data to get updated assigned students and project requests
      await fetchLecturerData();
      await fetchProjectRequests();
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Failed to approve request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Reject a project request
  Future<bool> rejectProjectRequest(String requestId, String rejectionReason) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update request status with rejection reason
      await _firestore.collection('project_requests').doc(requestId).update({
        'status': 'rejected',
        'dateRejected': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });
      
      // Remove from local pending requests
      _projectRequests.removeWhere((request) => request['id'] == requestId);
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Failed to reject request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Debug method to clear all allocations for this lecturer (for testing)
  Future<void> clearAllAllocations() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final lecturerId = _auth.currentUser!.uid;
      
      // Get all allocations for this lecturer
      final allocationsSnapshot = await _firestore
          .collection('allocations')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();
      
      // Delete each allocation
      for (var doc in allocationsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Clear local data
      _assignedStudents = [];
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to clear allocations: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to fetch all lecturers
  Future<void> fetchLecturers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final lecturersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'lecturer')
          .get();
      
      _allLecturers = await Future.wait(
        lecturersSnapshot.docs.map((doc) async {
          final lecturer = doc.data();
          final lecturerId = doc.id;
          
          // Get lecturer specializations
          final specializationsSnapshot = await _firestore
              .collection('users')
              .doc(lecturerId)
              .collection('specializations')
              .doc('specialization_data')
              .get();
          
          final List<String> specializations = [];
          if (specializationsSnapshot.exists) {
            final data = specializationsSnapshot.data();
            if (data != null && data['areas'] is List) {
              specializations.addAll(List<String>.from(data['areas']));
            }
          }
          
          return {
            ...lecturer,
            'id': lecturerId,
            'specializations': specializations,
          };
        }),
      );
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dispose method to clean up subscriptions
  @override
  void dispose() {
    _projectRequestsSubscription?.cancel();
    _allocationsSubscription?.cancel();
    _specializationChangeController.close();
    super.dispose();
  }

  // Start real-time project request updates
  void startRealtimeProjectRequestUpdates() {
    _projectRequestsSubscription?.cancel();
    
    final lecturerId = _auth.currentUser?.uid;
    if (lecturerId == null) return;
    
    _projectRequestsSubscription = _firestore
        .collection('project_requests')
        .where('lecturerId', isEqualTo: lecturerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) async {
        // Use microtask to avoid setState during build
        await Future.microtask(() async {
          try {
            List<Map<String, dynamic>> requests = [];
            
            for (var requestDoc in snapshot.docs) {
              final requestData = requestDoc.data();
              
              // Get student details
              final studentSnapshot = await _firestore
                  .collection('users')
                  .doc(requestData['studentId'])
                  .get();
              
              // Get topic details
              final topicSnapshot = await _firestore
                  .collection('topics')
                  .doc(requestData['topicId'])
                  .get();
              
              if (studentSnapshot.exists && topicSnapshot.exists) {
                requests.add({
                  'id': requestDoc.id,
                  'studentId': requestData['studentId'],
                  'studentName': studentSnapshot.data()?['name'] ?? 'Unknown Student',
                  'studentEmail': studentSnapshot.data()?['email'] ?? '',
                  'topicId': requestData['topicId'],
                  'topicTitle': topicSnapshot.data()?['title'] ?? 'Unknown Topic',
                  'dateRequested': requestData['dateRequested'],
                  'requestMessage': requestData['requestMessage'] ?? '',
                  'status': requestData['status'],
                });
              }
            }
            
            _projectRequests = requests;
            notifyListeners();
          } catch (e) {
            _error = 'Failed to load project requests: $e';
            notifyListeners();
          }
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

  // Start real-time allocation updates
  void startRealtimeAllocationUpdates() {
    _allocationsSubscription?.cancel();
    
    final lecturerId = _auth.currentUser?.uid;
    if (lecturerId == null) return;
    
    _allocationsSubscription = _firestore
        .collection('allocations')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .listen(
      (snapshot) async {
        try {
          List<Map<String, dynamic>> allocations = [];
          
          for (var allocDoc in snapshot.docs) {
            final allocation = allocDoc.data();
            
            // Get student details
            final studentSnapshot = await _firestore
                .collection('users')
                .doc(allocation['studentId'])
                .get();
            
            // Get topic details
            final topicSnapshot = await _firestore
                .collection('topics')
                .doc(allocation['topicId'])
                .get();
            
            if (studentSnapshot.exists && topicSnapshot.exists) {
              allocations.add({
                'id': allocDoc.id,
                'studentId': allocation['studentId'],
                'studentName': studentSnapshot.data()?['name'] ?? 'Unknown Student',
                'studentEmail': studentSnapshot.data()?['email'] ?? '',
                'topicId': allocation['topicId'],
                'topicTitle': topicSnapshot.data()?['title'] ?? 'Unknown Topic',
                'dateAllocated': allocation['dateAllocated'],
                'status': allocation['status'],
              });
            }
          }
          
          _assignedStudents = allocations;
          notifyListeners();
        } catch (e) {
          _error = 'Failed to load allocations: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        _error = 'Failed to load allocations: $error';
        notifyListeners();
      },
    );
  }

  // Stop real-time updates
  void stopRealtimeUpdates() {
    _projectRequestsSubscription?.cancel();
    _allocationsSubscription?.cancel();
  }
}