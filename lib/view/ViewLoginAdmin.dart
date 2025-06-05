import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/ControllerLogin.dart';
import '../model/ModelLogin.dart';

class ViewloginAdmin extends StatefulWidget {
  @override
  _ViewloginAdminState createState() => _ViewloginAdminState();
}

class _ViewloginAdminState extends State<ViewloginAdmin> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final ModelLogin _model;
  late final Controllerlogin _controller;

  final gradientColors = [
    Color(0xFF665C3C),
    Color(0xFF1E1E1E),
    Color(0xFF1E1E1E)
  ];

  @override
  void initState() {
    super.initState();
    _model = ModelLogin();
    _controller = Controllerlogin(_model);
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      // Sudah login → langsung ke admin
      Navigator.pushReplacementNamed(context, '/admin-page');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: [0.2, 0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: 50,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10, top: 10),
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                },
                icon: const Icon(Icons.home_filled, size: 30.0),
                color: Color(0xFFF2C94C),
              ),
            )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 120, 25, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/user_octagon.svg',
                  height: 140,
                  width: 140,
                  color: Color(0xFFF2C94C),
                ),
                SizedBox(height: 70),
                // _buildLabel('Username'),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person,
                ),
                SizedBox(height: 55),
                // _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                SizedBox(height: 60),
                _buildLoginButton(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Belum punya akun? Registrasi di sini'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: Colors.white), // teks input warna putih
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70), // label warna terang
        hintText: 'Masukkan $label',
        hintStyle: TextStyle(color: Colors.white54), // placeholder agak pudar
        filled: true,
        fillColor: Colors.black, // background field
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(6.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF2C94C), width: 2),
          borderRadius: BorderRadius.circular(6.0),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF2C94C),
          padding: EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onPressed: () {
          _model.username = _usernameController.text;
          _model.password = _passwordController.text;
          _controller.handleLogin(context);
        },
        child: Text(
          'LOGIN',
          style: TextStyle(
            fontSize: 30,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
