import 'package:flutter/material.dart';
import 'view/ViewAlarm.dart';
import 'view/ViewLoginAdmin.dart';
import 'view/ViewDrive.dart';
import 'view/ViewRegister.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => ViewAlarm());
      case '/login':
        return MaterialPageRoute(builder: (_) => ViewloginAdmin());
      case '/admin-page':
        return MaterialPageRoute(builder: (_) => Viewdrive());
      case '/register': // Tambahkan rute ini
        return MaterialPageRoute(builder: (_) => ViewRegister());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Page not found')),
      ),
    );
  }
}
