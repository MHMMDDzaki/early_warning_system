class ModelRegister {
  final String username;
  final String password;

  ModelRegister({required this.username, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }
}