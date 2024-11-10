import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:async';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // for json decoding

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

stopAlarm() {
  print('alarm stop');
  FlutterRingtonePlayer().stop();
}

startAlarm() {
  print('alarm start');
  FlutterRingtonePlayer().play(
    fromAsset: "assets/duarr.mp3",
    looping: true,
  );
}

class _MyAppState extends State<MyApp> {
  String _tempMessage = '';

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

  Future<void> fetchData() async {
    try {
      // final response = await http.get(Uri.parse('http://192.168.0.124:3000/api/fine'));
      final response = await http.get(Uri.parse('http://192.168.0.124:3000/api/trouble'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double number = double.parse(data['message']);
        if(number < 350) {
          setState(() {
            _tempMessage = 'aman';
          });
        } else {
          setState(() {
            _tempMessage = 'ga aman';
          });
          await enterKioskMode();
          await scheduleAlarm();
        }

      } else {
        print('Failed to load fine data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Alarm Manager with API'),
          elevation: 4,
          actions: [
            IconButton(
              onPressed: () async {
                await exitKioskMode();
                await scheduleCancelAlarm();
              },
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                child: Text('Fetch Fine Data and Alarm'),
                onPressed: () async {
                  await fetchData();  // Fetch data from API
                },
              ),
              SizedBox(height: 10),
              Text('Fine Message: $_tempMessage'),
            ],
          ),
        ),
      ),
    );
  }
}
