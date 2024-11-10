import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/ModelAlarm.dart';

class ControllerAlarm {
  ModelAlarm? _modelAlarm;

  startAlarm() {
    print('alarm start');
    FlutterRingtonePlayer().play(
      fromAsset: "assets/duarr.mp3",
      looping: true,
    );
  }

  stopAlarm() {
    print('alarm stop');
    FlutterRingtonePlayer().stop();
  }

  Future<void> scheduleAlarm() async {
    await AndroidAlarmManager.oneShot(
      const Duration(microseconds: 0),
      0,
      startAlarm(),
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> scheduleCancelAlarm() async {
    await AndroidAlarmManager.oneShot(
      const Duration(microseconds: 0),
      0,
      stopAlarm(),
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> enterKioskMode() async {
    try {
      await startKioskMode();
    } catch (e) {
      print("Error entering kiosk mode: $e");
    }
  }

  Future<void> exitKioskMode() async {
    try {
      await stopKioskMode();
    } catch (e) {
      print("Error exiting kiosk mode: $e");
    }
  }

  Future<String> fetchAlarmStatus() async {
    try {
      // final response = await http.get(Uri.parse('http://192.168.0.124:3000/api/fine'));
      final response = await http.get(Uri.parse('http://192.168.1.68:3000/api/trouble'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _modelAlarm = ModelAlarm.fromJson(data);
        return double.parse(_modelAlarm!.message) < 350 ? 'aman' : 'ga aman';
      } else {
        throw Exception('Failed to load fine data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}