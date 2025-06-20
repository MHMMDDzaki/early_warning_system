import 'package:flutter/material.dart';
import 'view/ViewAlarm.dart';
import 'view/ViewLoginAdmin.dart';
import 'view/ViewDrive.dart';
import 'view/ViewRegister.dart';
import 'view/ViewForgotPassword.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const ViewAlarm());
      case '/login':
        return MaterialPageRoute(builder: (_) => const ViewloginAdmin());
      case '/admin-page':
        return MaterialPageRoute(builder: (_) => const Viewdrive());
      case '/register': // Tambahkan rute ini
        return MaterialPageRoute(builder: (_) => const ViewRegister());
      case '/forgot-password': // <--- Tambahkan rute ini
        return MaterialPageRoute(builder: (_) => const ViewForgotPassword());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
