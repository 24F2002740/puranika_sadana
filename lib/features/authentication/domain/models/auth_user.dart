class AuthUser {
  final String uid;
  final String email;
  final String name;
  final String role;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  bool get isFamilyMember => role == 'family_member';
}