import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'BackgroundHandler.dart'; // Import background handler

/// Kelas ini bertanggung jawab untuk menginisialisasi semua layanan
/// yang dibutuhkan oleh aplikasi saat pertama kali berjalan.
class ServiceLocator {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Fungsi utama untuk menjalankan semua proses inisialisasi.
  static Future<void> initialize() async {
    // Muat environment variables dari file .env
    await dotenv.load(fileName: ".env");

    // Inisialisasi background service
    await _initializeBackgroundService();
  }

  /// Mengkonfigurasi dan menjalankan background service.
  static Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    // Minta izin notifikasi (wajib untuk Android 13+)
    await _requestNotificationPermission();

    // Buat channel notifikasi untuk foreground service
    const String notificationChannelId = 'my_app_foreground_service_channel';
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'RSAM Background Service',
      description: 'Channel for RSAM background updates and foreground service.',
      importance: Importance.low,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Konfigurasi service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: myBackgroundServiceOnStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'RSAM Service Booting',
        initialNotificationContent: 'Initializing, please wait...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(), // Konfigurasi untuk iOS (jika perlu)
    );
    print("MAIN: Background service CONFIGURED.");
  }

  /// Meminta izin notifikasi kepada pengguna.
  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print("MAIN: Notification permission GRANTED.");
      } else {
        print("MAIN: Notification permission DENIED by user.");
      }
    } else {
      print("MAIN: Notification permission already granted or not applicable.");
    }
  }
}