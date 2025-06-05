class ModelLogin {
  String username;
  String password;

  ModelLogin({this.username = '', this.password = ''});

  bool validate() {
    return username.isNotEmpty && password.isNotEmpty;
  }
}