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

  Future<void> _showAlertDialog(BuildContext context, String title, String message, {bool isSuccess = false, VoidCallback? onSuccessDismiss}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Atur radius sesuai keinginan
            side: const BorderSide(color: Colors.yellow, width: 2.0),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold,),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                if (isSuccess && onSuccessDismiss != null) {
                  onSuccessDismiss(); // Call additional action if provided
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> handleLogin(BuildContext context) async {
    if (!model.validate()) {
      await _showAlertDialog(
        context,
        'Input Validation',
        'Please fill all fields',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: const BorderSide(color: Colors.yellow, width: 2.0),
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow)),
              SizedBox(width: 20),
              Text("Logging in...", style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': model.username,
          'password': model.password,
        }),
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['token'] != null) {
          // Simpan token ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);

          await _showAlertDialog(
              context,
              'Login Successful',
              'You have successfully logged in.',
              isSuccess: true,
              onSuccessDismiss: () {
                // Pastikan context masih valid sebelum navigasi
                if (Navigator.of(context).canPop()) { // Cek apakah dialog sudah ditutup
                  // Atau cara lain, jika kita tidak ingin pop sebelum pushReplacementNamed
                }
                // Langsung navigasi setelah dialog ditutup oleh tombol OK
                Navigator.pushReplacementNamed(context, '/admin-page');
              }
          );
        } else {
          String errorMessage = data['message'] ?? 'Token missing or other login issue.';
          await _showAlertDialog(
            context,
            'Login Failed',
            'Login failed: $errorMessage',
          );
        }
      } else {
        String errorMessage = response.reasonPhrase ?? 'Unknown server error';
        try {
          // Coba parse body jika ada pesan error dari server
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          // Abaikan jika body tidak bisa di-parse, gunakan reasonPhrase
        }
        await _showAlertDialog(
          context,
          'Login Failed',
          'Login failed: $errorMessage (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) { // Tutup dialog loading jika masih terbuka karena error
        Navigator.of(context).pop();
      }
      await _showAlertDialog(
        context,
        'Error',
        'An unexpected error occurred: $e',
      );
    }
  }
}