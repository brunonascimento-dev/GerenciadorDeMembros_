class AppUser {
  final String id;
  final String email;
  final String role; // 'admin' ou 'leader'
  final String? congregationId; // Só preenchido se for leader

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.congregationId,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'leader',
      congregationId: data['congregationId'],
    );
  }

  // Atalho para saber se é Pastor
  bool get isAdmin => role == 'admin';
}