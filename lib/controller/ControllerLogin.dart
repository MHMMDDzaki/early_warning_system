import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/ModelLogin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Controllerlogin {
  final ModelLogin model;
  final baseUrl = dotenv.env['BASE_URL'];

  Controllerlogin(this.model);

  Future<void> handleLogin(BuildContext context) async {
    if (!model.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': model.username,
          'password': model.password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['token'] != null) {
          // Simpan token ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          print(data['token']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful')),
          );

          Navigator.pushReplacementNamed(context, '/admin-page');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed: Token missing')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}