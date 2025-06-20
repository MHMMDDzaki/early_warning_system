import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/ControllerLogin.dart';
import '../model/ModelLogin.dart';

class ViewloginAdmin extends StatefulWidget {
  const ViewloginAdmin({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ViewloginAdminState createState() => _ViewloginAdminState();
}

class _ViewloginAdminState extends State<ViewloginAdmin> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final ModelLogin _model;
  late final Controllerlogin _controller;

  final gradientColors = [
    const Color(0xFF665C3C),
    const Color(0xFF1E1E1E),
    const Color(0xFF1E1E1E)
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
      if(!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/admin-page', (route) => false);
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
          stops: const [0.2, 0.6, 1.0],
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
              padding: const EdgeInsets.only(right: 10, top: 10),
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                },
                icon: const Icon(Icons.home_filled, size: 30.0),
                color: const Color(0xFFF2C94C),
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
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFF2C94C),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 70),
                // _buildLabel('Username'),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person,
                ),
                const SizedBox(height: 55),
                // _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 60),
                _buildLoginButton(),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
                      },
                      child: const Text('Sign In', style: TextStyle(color: Color(0xFFF2C94C), fontSize: 16),),
                    ),
                    const Text('|', style: TextStyle(color: Color(0xFFF2C94C), fontWeight: FontWeight.bold, fontSize: 20),),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/forgot-password', (route) => false);
                      },
                      child: const Text(
                        'Forgot Password',
                        style:
                        TextStyle(color: Color(0xFFF2C94C), fontSize: 16), // Sesuaikan style
                      ),
                    ),
                  ],
                ),
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
      style: const TextStyle(color: Colors.white), // teks input warna putih
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70), // label warna terang
        hintText: 'Masukkan $label',
        hintStyle: const TextStyle(color: Colors.white54), // placeholder agak pudar
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
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(6.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFF2C94C), width: 2),
          borderRadius: BorderRadius.circular(6.0),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
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
          backgroundColor: const Color(0xFFF2C94C),
          padding: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onPressed: () {
          _model.username = _usernameController.text;
          _model.password = _passwordController.text;
          _controller.handleLogin(context);
        },
        child: const Text(
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
