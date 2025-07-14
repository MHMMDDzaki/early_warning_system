class UserModel {
  final String id;
  final String username;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.status,
  });

  // Factory constructor untuk membuat instance UserModel dari JSON map.
  // Ini sangat berguna saat mem-parsing data dari API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '', // Memberikan nilai default jika null
      username: json['username'] ?? 'N/A',
      role: json['role'] ?? 'N/A',
      status: json['status'] ?? 'N/A',
    );
  }
}