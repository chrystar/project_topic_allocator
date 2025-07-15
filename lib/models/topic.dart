// Topic model for MVVM architecture
class Topic {
  final String id;
  final String title;
  final String description;
  final String lecturerId;
  final int maxStudents;
  final List<String> technologies;
  final List<String> areas;
  final List<String> specializations;

  Topic({
    required this.id, 
    required this.title, 
    required this.description, 
    required this.lecturerId, 
    required this.maxStudents,
    this.technologies = const [],
    this.areas = const [],
    this.specializations = const [],
  });
}
