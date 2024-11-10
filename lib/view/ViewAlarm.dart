import 'package:flutter/material.dart';
import '../controller/ControllerAlarm.dart';

class ViewAlarm extends StatefulWidget {
  @override
  _AlarmViewState createState() => _AlarmViewState();
}

class _AlarmViewState extends State<ViewAlarm> {
  final ControllerAlarm _controller = ControllerAlarm();
  String _tempMessage = '';

  Future<void> _fetchAndHandleData() async {
    String status = await _controller.fetchAlarmStatus();
    setState(() {
      _tempMessage = status;
    });

    if (status == 'ga aman') {
      await _controller.enterKioskMode();
      await _controller.scheduleAlarm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Manager with API'),
        elevation: 4,
        actions: [
          IconButton(
            onPressed: () async {
              await _controller.exitKioskMode();
              await _controller.scheduleCancelAlarm();
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
              onPressed: _fetchAndHandleData,
            ),
            SizedBox(height: 10),
            Text('Fine Message: $_tempMessage'),
          ],
        ),
      ),
    );
  }
}
