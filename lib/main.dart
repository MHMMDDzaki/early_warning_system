import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget  {
  @override
  _MyAppState createState() => _MyAppState();
}

showprint() {
  print('alarm done');
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: OutlinedButton(
            child: Text('Alarm now'),
            onPressed: () {
              AndroidAlarmManager.oneShot(Duration(seconds: 3), 0, showprint);
            },
          ),
        ),
      ),
    );
  }
}
