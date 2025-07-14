import 'package:flutter/material.dart';

/// Kunci global untuk mengakses Navigator dari mana saja di aplikasi.
/// Ini berguna untuk navigasi yang dipicu dari background service.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// State global yang menandakan apakah UI alarm sedang aktif (menampilkan dialog).
/// Menggunakan ValueNotifier agar widget bisa "mendengarkan" perubahannya.
final ValueNotifier<bool> isAlarmGloballyActive = ValueNotifier<bool>(false);