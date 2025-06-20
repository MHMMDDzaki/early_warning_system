import 'package:flutter/material.dart';
import '../controller/ControllerForgotPassword.dart';

class ViewForgotPassword extends StatefulWidget {
  const ViewForgotPassword({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ViewForgotPasswordState createState() => _ViewForgotPasswordState();
}

class _ViewForgotPasswordState extends State<ViewForgotPassword> {
  final _formKeyUsername = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final ControllerForgotPassword _controller = ControllerForgotPassword();

  bool _isLoadingValidate = false;
  bool _isLoadingReset = false;
  bool _showPasswordFields = false;
  String? _resetToken;
  String? _validatedUsername; // Untuk menyimpan username yang sudah divalidasi

  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _newPasswordVisible = false;
    _confirmPasswordVisible = false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _submitValidateUsername() async {
    if (_formKeyUsername.currentState!.validate()) {
      setState(() {
        _isLoadingValidate = true;
        _showPasswordFields = false; // Sembunyikan field password jika validasi ulang
        _resetToken = null;
        _validatedUsername = null;
      });

      try {
        final response = await _controller.validateUsername(_usernameController.text.trim());
        if (mounted) {
          setState(() {
            _resetToken = response.token;
            _validatedUsername = _usernameController.text.trim(); // Simpan username
            _showPasswordFields = true;
          });
          await _showAlertDialog(
            context,
            'Validasi Berhasil',
            response.message,
            isSuccess: true, // Tandai sebagai sukses jika perlu aksi berbeda
          );
        }
      } catch (e) {
        if (mounted) {
          await _showAlertDialog(
            context,
            'Validasi Gagal',
            e.toString().replaceFirst("Exception: ", ""),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingValidate = false;
          });
        }
      }
    }
  }

  Future<void> _submitResetPassword() async {
    if (_formKeyPassword.currentState!.validate()) {
      if (_resetToken == null || _validatedUsername == null) {
        await _showAlertDialog(
          context,
          'Peringatan',
          'Token atau username tidak valid. Silakan validasi ulang username.',
        );
        return;
      }
      setState(() {
        _isLoadingReset = true;
      });

      try {
        final response = await _controller.resetPassword(
          username: _validatedUsername!,
          token: _resetToken!,
          newPassword: _newPasswordController.text,
        );
        if (mounted) {
          await _showAlertDialog(
            context,
            'Reset Password Berhasil',
            response.message,
            isSuccess: true,
            onSuccessDismiss: () {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          );
        }
      } catch (e) {
        if (mounted) {
          await _showAlertDialog(
            context,
            'Reset Password Gagal',
            e.toString().replaceFirst("Exception: ", ""),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingReset = false;
          });
        }
      }
    }
  }

  Widget _buildUsernameSection() {
    return Form(
      key: _formKeyUsername,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.person, color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white70)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFF2C94C))),
              filled: true,
              fillColor: Colors.black.withAlpha((255 * 0.3).round()),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _isLoadingValidate
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2C94C)))
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(fontSize: 16, color: Colors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: _submitValidateUsername,
            child: const Text('VALIDASI USERNAME', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    if (!_showPasswordFields) {
      return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika tidak perlu
    }
    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          const Text(
            'Masukkan Password Baru',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Password Baru
          TextFormField(
            controller: _newPasswordController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password Baru',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white70)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFF2C94C))),
              filled: true,
              fillColor: Colors.black.withAlpha((255 * 0.3).round()),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _newPasswordVisible = !_newPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_newPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password baru tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Konfirmasi Password Baru
          TextFormField(
            controller: _confirmPasswordController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password Baru',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white70)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFF2C94C))),
              filled: true,
              fillColor: Colors.black.withAlpha((255 * 0.3).round()),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_confirmPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password tidak boleh kosong';
              }
              if (value != _newPasswordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          _isLoadingReset
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2C94C)))
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(fontSize: 18, color: Colors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: _submitResetPassword,
            child: const Text('RESET PASSWORD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton( // Tombol kembali
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Lupa Password Anda?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Masukkan username Anda untuk mendapatkan token reset.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              _buildUsernameSection(),
              _buildPasswordSection(), // Akan muncul kondisional
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text(
                  'Kembali ke Login',
                  style: TextStyle(color: Color(0xFFF2C94C)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}