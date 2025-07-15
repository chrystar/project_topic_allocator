// Matching algorithm class for enhanced matching between students, topics and lecturers

import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingAlgorithm {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Weight factors for different match aspects (can be adjusted)
  static const double _projectTechWeight = 0.6;
  static const double _projectAreaWeight = 0.4;
  static const double _lecturerSpecWeight = 1.0;
  
  /// Find matches between a student and projects/lecturers
  /// Returns a consolidated result with both matching projects and lecturers
  Future<Map<String, dynamic>> findMatchesForStudent({
    required String studentId,
    bool includeDetailedScores = false,
  }) async {
    // Get student interests
    final studentInterestsDoc = await _firestore
        .collection('interests')
        .doc(studentId)
        .get();
    
    if (!studentInterestsDoc.exists) {
      throw Exception('Student interests not found');
    }
    
    final studentInterests = List<String>.from(
        studentInterestsDoc.data()?['interests'] ?? []);
    
    if (studentInterests.isEmpty) {
      throw Exception('Student has not selected any interests');
    }
    
    // Find matching projects and lecturers concurrently
    final results = await Future.wait([
      _findMatchingProjects(studentId, studentInterests, includeDetailedScores),
      _findMatchingLecturers(studentId, studentInterests, includeDetailedScores),
    ]);
    
    return {
      'projects': results[0],
      'lecturers': results[1],
      'studentInterests': studentInterests,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// Find projects that match student interests
  Future<List<Map<String, dynamic>>> _findMatchingProjects(
    String studentId, 
    List<String> studentInterests,
    bool includeDetailedScores
  ) async {
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
      
      // Calculate match scores separately for technologies and areas
      final techMatches = _calculateMatches(studentInterests, topicTechnologies);
      final areaMatches = _calculateMatches(studentInterests, topicAreas);
      
      // Weighted score calculation
      final weightedScore = (techMatches.length * _projectTechWeight) + 
                           (areaMatches.length * _projectAreaWeight);
      
      // Overall match percentage relative to student interests
      final overallMatchPercentage = (weightedScore / 
          (studentInterests.length * Math.max(_projectTechWeight, _projectAreaWeight))) * 100;
      
      // All matching areas (for display)
      final allMatchingAreas = {...techMatches, ...areaMatches}.toList();
      
      // Only include if there's at least one match
      if (allMatchingAreas.isNotEmpty) {
        // Get lecturer details
        final lecturerId = topic['lecturerId'];
        final lecturerDoc = await _firestore.collection('users').doc(lecturerId).get();
        final lecturer = lecturerDoc.data() ?? {};
        
        final projectMatch = {
          'id': topicId,
          'title': topic['title'] ?? 'Unknown',
          'description': topic['description'] ?? '',
          'lecturer': {
            'id': lecturerId,
            'name': lecturer['name'] ?? 'Unknown',
            'email': lecturer['email'] ?? '',
          },
          'matchScore': weightedScore,
          'matchPercentage': overallMatchPercentage.clamp(0, 100),
          'matchingAreas': allMatchingAreas,
          'technologies': topicTechnologies,
          'areas': topicAreas,
        };
        
        // Add detailed scores if requested
        if (includeDetailedScores) {
          projectMatch['detailedScores'] = {
            'techMatches': techMatches,
            'areaMatches': areaMatches,
            'techMatchScore': techMatches.length * _projectTechWeight,
            'areaMatchScore': areaMatches.length * _projectAreaWeight,
          };
        }
        
        matchingProjects.add(projectMatch);
      }
    }
    
    // Sort by match score (highest first)
    matchingProjects.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
    
    return matchingProjects;
  }
  
  /// Find lecturers that match student interests
  Future<List<Map<String, dynamic>>> _findMatchingLecturers(
    String studentId, 
    List<String> studentInterests,
    bool includeDetailedScores
  ) async {
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
      
      // Calculate match between student interests and lecturer specializations
      final specMatches = _calculateMatches(studentInterests, lecturerSpecializations);
      
      // Calculate weighted score
      final weightedScore = specMatches.length * _lecturerSpecWeight;
      
      // Overall match percentage relative to student interests
      final overallMatchPercentage = (weightedScore / 
          (studentInterests.length * _lecturerSpecWeight)) * 100;
      
      // Only include if there's at least one match
      if (specMatches.isNotEmpty) {
        final lecturerMatch = {
          'id': lecturerId,
          'name': lecturer['name'] ?? 'Unknown',
          'department': lecturer['department'] ?? 'Unknown',
          'email': lecturer['email'] ?? '',
          'matchScore': weightedScore,
          'matchPercentage': overallMatchPercentage.clamp(0, 100),
          'matchingAreas': specMatches,
          'specializations': lecturerSpecializations,
        };
        
        // Add detailed scores if requested
        if (includeDetailedScores) {
          lecturerMatch['detailedScores'] = {
            'specMatches': specMatches,
            'specMatchScore': specMatches.length * _lecturerSpecWeight,
          };
        }
        
        matchingLecturers.add(lecturerMatch);
      }
    }
    
    // Sort by match score (highest first)
    matchingLecturers.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
    
    return matchingLecturers;
  }
  
  /// Recalculate all matches for students interested in a lecturer's specializations
  Future<void> recalculateMatchesForLecturerChange(String lecturerId) async {
    // Get the lecturer's updated specializations
    final lecturerDoc = await _firestore.collection('users').doc(lecturerId).get();
    final specializations = List<String>.from(lecturerDoc.data()?['specializations'] ?? []);
    
    // Find students with matching interests
    final studentsQuery = await _firestore.collection('interests').get();
    
    for (var studentDoc in studentsQuery.docs) {
      final studentId = studentDoc.id;
      final studentInterests = List<String>.from(studentDoc.data()['interests'] ?? []);
      
      // Check if student has any matching interests with lecturer's specializations
      final hasMatchingInterests = studentInterests
          .any((interest) => specializations.contains(interest));
      
      if (hasMatchingInterests) {
        // Recalculate matches for this student
        final newMatches = await findMatchesForStudent(
          studentId: studentId,
          includeDetailedScores: true
        );
        
        // Store updated recommendations
        await _firestore.collection('recommendations').doc(studentId).set({
          'matches': newMatches,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Get real-time recommendations for a student
  Stream<Map<String, dynamic>> getRealtimeRecommendations(String studentId) {
    return _firestore
        .collection('recommendations')
        .doc(studentId)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }
  
  /// Helper method to calculate matching elements between two lists
  Set<String> _calculateMatches(List<String> list1, List<String> list2) {
    return list1.where((item) => list2.contains(item)).toSet();
  }
}

// Math utility class
class Math {
  static double max(double a, double b) => (a > b) ? a : b;
}
