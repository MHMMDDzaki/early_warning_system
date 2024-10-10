import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget  {
  @override
  _MyAppState createState() => _MyAppState();
}

stopAlarm() {
  print('alarm stop');
  FlutterRingtonePlayer().stop();
}

startAlarm() {
  print('alarm start');
  FlutterRingtonePlayer()
      .play(fromAsset: "assets/duarr.mp3", looping: true,);

  Timer(const Duration(seconds: 5), () {
    stopAlarm();
  });
}


class _MyAppState extends State<MyApp> {

  Future<void> scheduleAlarm() async {
    await AndroidAlarmManager.oneShot(
      const Duration(microseconds: 0),
      0,
      startAlarm(),
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );

    // Automatically stop the alarm after 5 seconds
    Timer(const Duration(seconds: 2), () {
      scheduleCancelAlarm();
    });
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Android alarm manager plus example'),
          elevation: 4,
          actions: [
            IconButton(
              onPressed: () {
                scheduleCancelAlarm();
              },
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
        body: Center(
          child: OutlinedButton(
            child: Text('Alarm now'),
            onPressed: () async {
              await scheduleAlarm();
            },
          ),
        ),
      ),
    );
  }
}
