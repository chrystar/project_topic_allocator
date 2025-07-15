// LecturerProfile model for MVVM architecture
class LecturerProfile {
  final String userId;
  final List<String> specializations;
  final List<String> topicIds;

  LecturerProfile({required this.userId, required this.specializations, required this.topicIds});
}
