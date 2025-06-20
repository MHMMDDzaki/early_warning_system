import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/ModelAlarm.dart';

class ControllerAlarm {
  ModelAlarm? _modelAlarm;
  String? audioUrlFromApi;
  final baseUrl = dotenv.env['BASE_URL'];
  final configId = dotenv.env['CONFIG_ID'];
  AudioPlayer player = AudioPlayer();

  Future<void> init() async {
    await getTriggerValues();
  }

  startAlarm() async {
    if (audioUrlFromApi == null || audioUrlFromApi!.isEmpty) {
      return;
    }
    try {
      await player.play(UrlSource(audioUrlFromApi!));
      player.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint("Gagal memutar audio: $e");
    }
  }

  stopAlarm() {
    player.stop();
  }

  void dispose() {
    player.dispose();
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
      debugPrint("Error entering kiosk mode: $e");
    }
  }

  Future<void> exitKioskMode() async {
    try {
      await stopKioskMode();
    } catch (e) {
      debugPrint("Error exiting kiosk mode: $e");
    }
  }

  Future<double> fetchAlarmStatus(int maxRsam) async {
    try {
      final response = await http.get(
        // Uri.parse('$baseUrl/api/rsam-latest?maxRsam=$maxRsam'),
        Uri.parse('$baseUrl/api/rsamv2-latest'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _modelAlarm = ModelAlarm.fromJson(jsonData);
        return _modelAlarm!.rsamValue;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch RSAM: $e');
    }
  }

  Future<Map<String, dynamic>> getTriggerValues() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rsam-config/$configId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        audioUrlFromApi = jsonData['audio_url'];

        return {
          'triggerOn': jsonData['trigger_on'] as int,
          'triggerOff': jsonData['trigger_off'] as int,
          'audioUrl': jsonData['audio_url'],
        };
      }

      throw Exception('Failed to load config. Status: ${response.statusCode}');

    } catch (e) {
      return {
        'triggerOn': 26000,  // Default sesuai contoh API
        'triggerOff': 500,
        'audioUrl': null,
      };
    }
  }

  Future<List<dynamic>> fetchChartDataRange(String apiRange) async {
    final String apiUrl = '$baseUrl/api/rsamv2-latest/range?range=$apiRange';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        // Ekstrak array dari properti 'data'
        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
          return decodedBody['data'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format: $decodedBody');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch chart data: $e');
    }
  }
}