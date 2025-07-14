import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controller/ControllerAlarm.dart'; // Sesuaikan path jika perlu

@pragma('vm:entry-point')
Future<void> myBackgroundServiceOnStart(ServiceInstance service) async {
  bool isAlarmActiveInBackground = false;
  bool isAlarmSilencedManually = false;

  try {
    DartPluginRegistrant.ensureInitialized();
    await dotenv.load(fileName: ".env");
    final controllerAlarm = ControllerAlarm.instance;
    await controllerAlarm.init();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          // Update notifikasi setelah event
          title: "RSAM Service (FG Event)",
          content: "Service now foreground.",
        );
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      // ---- PENTING: Update notifikasi pertama dari onStart ----
      service.setForegroundNotificationInfo(
        title: "RSAM Service Active", // Judul baru
        content: "RSAM: Initializing...", // Konten baru
      );
      // --------------------------------------------------------
    } else {
      print(
          'BG_HANDLER_LOG: Service is NOT AndroidServiceInstance. Cannot set notification.');
    }

    service.on('stopService').listen((event) {
      controllerAlarm.dispose();
      service.stopSelf();
    });

    service.on('resetAlarmState').listen((event) {
      isAlarmSilencedManually = true;
      controllerAlarm.stopAlarm();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // Ambil nilai trigger dan status RSAM
        final triggers = await controllerAlarm.getTriggerValues();
        final triggerOn = triggers['triggerOn'] as int;
        final triggerOff = triggers['triggerOff'] as int;
        final rsamValue = await controllerAlarm.fetchAlarmStatus(0);

        // Update notifikasi reguler
        if (service is AndroidServiceInstance &&
            await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "RSAM Service Active",
            content: "RSAM: ${rsamValue.toStringAsFixed(2)}",
          );
        }

        // ### LOGIKA INTI UNTUK ALARM ###
        if (rsamValue > triggerOn && !isAlarmActiveInBackground && !isAlarmSilencedManually) {
          isAlarmActiveInBackground = true;

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "!!! ALARM TERDETEKSI !!!",
              content:
                  "Nilai RSAM ${rsamValue.toStringAsFixed(2)}. Ketuk untuk membuka.",
            );
          }

          service.invoke('startAlarmUI');
          service.invoke('forceOpenAlarm');
          controllerAlarm.startAlarm();
        } else if (rsamValue <= triggerOff && isAlarmActiveInBackground) {
          isAlarmActiveInBackground = false;
          isAlarmSilencedManually = false;
        }
      } catch (e) {
        print('BG_HANDLER_LOG: Error in timer loop: $e');
      }
    });
  } catch (e, s) {
    // Tambahkan StackTrace
    print('BG_HANDLER_LOG: !!!!!!! CRITICAL ERROR IN onStart !!!!!!!');
    print('BG_HANDLER_LOG: ERROR: $e');
    print('BG_HANDLER_LOG: STACKTRACE: $s');
    // Coba update notifikasi dengan pesan error jika memungkinkan
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "RSAM Service Failed",
        content: "Startup Error. Check Logs.", // Pesan lebih jelas
      );
    }
  }
}
