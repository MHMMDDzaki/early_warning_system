import 'package:flutter/material.dart';
import 'RouteGenerator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'service/ServiceLocator.dart'; // -> Import file baru
import 'state/AppState.dart';

void main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode async.
  WidgetsFlutterBinding.ensureInitialized();

  // Panggil satu fungsi untuk menginisialisasi semua layanan.
  await ServiceLocator.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String dataFromService = "Waiting for data from service...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // observer

    final service = FlutterBackgroundService();

    service.on('startAlarmUI').listen((event) {
      print("MAIN: Menerima 'startAlarmUI', mengubah isAlarmGloballyActive menjadi true.");
      isAlarmGloballyActive.value = true;
    });

    service.on('forceOpenAlarm').listen((event) {
      // Pastikan ada navigator yang bisa digunakan
      if (navigatorKey.currentState != null) {
        print("MAIN: Menerima 'forceOpenAlarm', navigasi ke halaman utama.");
        // Navigasi paksa ke halaman utama ('/') dan hapus semua halaman sebelumnya
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // AppLifecycleState.detached means the app is about to be destroyed
    if (state == AppLifecycleState.detached) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        textTheme: GoogleFonts.leagueGothicTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
