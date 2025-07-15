// User model for MVVM architecture
class User {
  final String id;
  final String name;
  final String email;
  final String role; // student, lecturer, admin

  User({required this.id, required this.name, required this.email, required this.role});
}
