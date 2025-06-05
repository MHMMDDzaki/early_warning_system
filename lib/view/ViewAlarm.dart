import 'package:flutter/material.dart';
import '../controller/ControllerAlarm.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

class ViewAlarm extends StatefulWidget {
  @override
  _AlarmViewState createState() => _AlarmViewState();
}

class _AlarmViewState extends State<ViewAlarm> {
  final ControllerAlarm _controller = ControllerAlarm();
  double rsamValue = 0.0;
  String result = '';
  bool isAlarmClosed = false;
  bool isLockMode = false;
  bool isLoading = false; // Untuk loading navigasi
  bool _isChartLoading = false; // Untuk loading chart
  late Timer _dataTimer;
  late Timer _paramTimer;
  late Timer _volumeTimer;
  int _currentMaxRsam = 400;
  int _triggerOn = 1000;
  int _triggerOff = 280;
  bool isDriveInitialized = false;
  List<_ChartData> chartData = []; // Menggunakan _ChartData
  late int _selectedDurationMinutes;
  late String _selectedApiRange;

  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '30M', 'minutes': 30, 'apiRange': '30m'},
    {'label': '1H', 'minutes': 60, 'apiRange': '1h'},
    {'label': '2H', 'minutes': 120, 'apiRange': '2h'},
    {'label': '4H', 'minutes': 240, 'apiRange': '4h'},
    {'label': '8H', 'minutes': 480, 'apiRange': '8h'},
    {'label': '16H', 'minutes': 960, 'apiRange': '16h'},
    {'label': '1d', 'minutes': 1440, 'apiRange': '1d'},
    {'label': '2d', 'minutes': 2880, 'apiRange': '2d'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    await _controller.init();
    if (!mounted) return;
    setState(() => isDriveInitialized = true);
    _selectedDurationMinutes = _durationOptions[0]['minutes'];
    _selectedApiRange = _durationOptions[0]['apiRange'];
    // _setupTimers();
    _updateChartData();
    // VolumeController.instance.setVolume(1.0);
  }

  void _onDurationSelected(int minutes, String apiRange) {
    if (!mounted) return;

    setState(() {
      _selectedDurationMinutes = minutes;
      _selectedApiRange = apiRange;
    });

    _updateChartData();
  }

  Future<void> _fetchChartDataFromController(String apiRange) async {
    if (!mounted) return;
    setState(() => _isChartLoading = true);

    List<_ChartData> newChartData = [];
    try {
      List<dynamic> responseData =
          await _controller.fetchChartDataRange(apiRange);

      // Proses agregasi data berdasarkan rentang waktu
      if (_selectedDurationMinutes == 2880) {
        // Hitung interval dalam menit (2 menit per jam)
        int intervalMinutes = 4 * (_selectedDurationMinutes ~/ 60);
        newChartData = _aggregateData(responseData, intervalMinutes);
      } else if (_selectedDurationMinutes > 30) {
        int intervalMinutes = 2 * (_selectedDurationMinutes ~/ 60);
        newChartData = _aggregateData(responseData, intervalMinutes);
      } else {
        // Untuk 30 menit, tampilkan semua data tanpa agregasi
        for (int i = 0; i < responseData.length; i++) {
          final item = responseData[i] as Map<String, dynamic>;
          double rsamVal = (item['RSAM'] as num?)?.toDouble() ?? 0.0;
          String timestamp = item['Timestamp']?.toString() ?? '';
          String timeLabel = _formatTimeLabel(timestamp);
          newChartData.add(_ChartData(timeLabel, rsamVal));
        }
      }
    } catch (e) {
      print('Error processing chart data: $e');
    }

    if (!mounted) return;
    setState(() {
      chartData = newChartData;
      _isChartLoading = false;
    });
  }

// Fungsi agregasi data
  List<_ChartData> _aggregateData(List<dynamic> rawData, int intervalMinutes) {
    List<_ChartData> aggregatedData = [];
    List<Map<String, dynamic>> dataList =
        List<Map<String, dynamic>>.from(rawData);

    // Urutkan data berdasarkan timestamp
    dataList.sort((a, b) {
      DateTime? timeA = _parseTimestamp(a['Timestamp']);
      DateTime? timeB = _parseTimestamp(b['Timestamp']);
      return timeA?.compareTo(timeB ?? DateTime.now()) ?? 0;
    });

    DateTime? currentGroupTime;
    double currentMaxRsam = 0.0;
    int pointsInGroup = 0;

    for (var item in dataList) {
      DateTime? timestamp = _parseTimestamp(item['Timestamp']);
      double rsamVal = (item['RSAM'] as num?)?.toDouble() ?? 0.0;

      if (timestamp == null) continue;

      if (currentGroupTime == null) {
        // Kelompok pertama
        currentGroupTime = timestamp;
        currentMaxRsam = rsamVal;
        pointsInGroup = 1;
      } else {
        // Hitung selisih waktu dalam menit
        int diffMinutes = timestamp.difference(currentGroupTime!).inMinutes;

        if (diffMinutes < intervalMinutes) {
          // Masih dalam kelompok yang sama
          if (rsamVal > currentMaxRsam) {
            currentMaxRsam = rsamVal;
          }
          pointsInGroup++;
        } else {
          // Kelompok baru
          aggregatedData.add(_ChartData(
              _formatTimeLabel(currentGroupTime.toString()), currentMaxRsam));

          // Reset untuk kelompok baru
          currentGroupTime = timestamp;
          currentMaxRsam = rsamVal;
          pointsInGroup = 1;
        }
      }
    }

    // Tambahkan kelompok terakhir
    if (pointsInGroup > 0) {
      aggregatedData.add(_ChartData(
          _formatTimeLabel(currentGroupTime.toString()), currentMaxRsam));
    }

    return aggregatedData;
  }

// Helper untuk parsing timestamp
  DateTime? _parseTimestamp(String? timestamp) {
    if (timestamp == null) return null;
    try {
      // Format: "2025-06-03 14:12:54"
      return DateTime.parse(timestamp.replaceAll(' ', 'T'));
    } catch (e) {
      return null;
    }
  }

// Helper untuk format label waktu (HH:mm)
  String _formatTimeLabel(String fullTimestamp) {
    try {
      if (fullTimestamp.isNotEmpty) {
        final timePart = fullTimestamp.split(' ')[1];
        return timePart.substring(0, 5); // Ambil HH:mm
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return fullTimestamp; // Fallback ke timestamp penuh
  }

  void _updateChartData() async {
    final selectedOption = _durationOptions.firstWhere(
      (opt) => opt['minutes'] == _selectedDurationMinutes,
      orElse: () => _durationOptions.first,
    );
    final String apiRange = selectedOption['apiRange'];
    await _fetchChartDataFromController(apiRange); // Panggil metode baru
  }

  void _setupTimers() {
    // Update parameter setiap 5 detik
    // _paramTimer = Timer.periodic(Duration(seconds: 60), (timer) {
    //   setState(() => _currentMaxRsam += 100);
    //   print('New maxRsam: $_currentMaxRsam');
    // });

    // _volumeTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
    // if (!mounted) {
    //   timer.cancel(); // Batalkan timer ini
    //   return;
    // }
    //   try {
    //     double volume = await VolumeController.instance.getVolume();
    //
    //     if (volume < 1.0) {
    //       VolumeController.instance.setVolume(1.0);
    //     }
    //   } catch (e) {
    //     print(e);
    //   }
    // });

    // Fetch data setiap 1 detik
    _dataTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel(); // Batalkan timer ini
        return;
      }
      if (!isDriveInitialized) return;


      final triggers = await _controller.getTriggerValues();
      if (!mounted) return;
      setState(() {
        _triggerOn = triggers['triggerOn']!;
        _triggerOff = triggers['triggerOff']!;
      });

      try {
        final value = await _controller.fetchAlarmStatus(_currentMaxRsam);
        if (!mounted) return;
        setState(() {
          rsamValue = value;
          result = value.toStringAsFixed(2);
        });

        if (value > _triggerOn && !isAlarmClosed && !isLockMode) {
          if (!mounted) return;
          await _handleAlarmActivation();
        } else if (value <= _triggerOff && isAlarmClosed) {
          isAlarmClosed = false;
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    });
  }

  Future<void> _handleAlarmActivation() async {
    setState(() => isLockMode = true);
    _showWarningDialog();
    await _controller.enterKioskMode();
    await _controller.scheduleAlarm();
  }

  @override
  void dispose() {
    // _initializeApp();
    _dataTimer.cancel();
    _paramTimer.cancel();
    _volumeTimer.cancel();
    super.dispose();
  }

  void _showWarningDialog() {
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (parentContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Hilangkan padding default
        child: Container(
          width: screenWidth, // Lebar penuh layar// Margin sisi kiri-kanan
          decoration: BoxDecoration(
            color: Colors.black87,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/outline_circle.svg',
                    height: 150,
                    width: 150,
                    color: Color(0xFFE41D1D),
                  ),
                  SvgPicture.asset(
                    'assets/icons/triangle_warning.svg',
                    height: 100,
                    width: 100,
                    color: Color(0xFFE41D1D),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ALARM TRIGGERED!',
                      style: TextStyle(
                        color: Color(0xFFE41D1D),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tekan tombol di bawah untuk menghentikan alarm.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFE41D1D),
                    side: BorderSide.none,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    await _showConfirmationDialog(parentContext);
                  },
                  child: Text(
                    'Stop Alarm',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext parentContext) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop Alarm'),
        content: Text('Are you sure you want to stop the alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                isAlarmClosed = true;
                isLockMode = false;
              });
              Navigator.pop(context);
              Navigator.pop(parentContext);
              await _controller.exitKioskMode();
              await _controller.scheduleCancelAlarm();
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = isLockMode
        ? [Color(0xFFA02D2D), Color(0xFF1E1E1E), Color(0xFF1E1E1E)]
        : [Color(0xFF665C3C), Color(0xFF1E1E1E), Color(0xFF1E1E1E)];

    final textColor = isLockMode ? Color(0xFFE41D1D) : Color(0xFFF2C94C);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: [0.2, 0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 80,
          actions: [
            Padding(
              padding: EdgeInsets.only(top: 12.0, right: 20.0),
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/user_octagon.svg',
                  height: 40,
                  width: 40,
                  colorFilter:
                      ColorFilter.mode(Color(0xFFF2C94C), BlendMode.srcIn),
                ),
                onPressed: () async {
                  if (!mounted) return;
                  setState(() => isLoading = true);
                  await Future.delayed(Duration(milliseconds: 100));
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRsamDisplay(textColor),
                    SizedBox(height: 20),
                    _buildDurationSelector(),
                    SizedBox(height: 20),
                    _buildChartArea(),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.yellow,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: _durationOptions.length,
        itemBuilder: (context, index) {
          final duration = _durationOptions[index];
          bool isSelected = _selectedDurationMinutes == duration['minutes'];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4), // Jarak antar item
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: Color.fromRGBO(255,235,59, 0.2),
              ),
              onPressed: () {
                _onDurationSelected(duration['minutes'], duration['apiRange']);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.yellow : Colors.grey,
                      width: 4.0,
                    ),
                  ),
                ),
                child: Text(
                  duration['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.yellow : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartArea() {
    if (_isChartLoading) {
      return Container(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: Colors.yellow)),
      );
    }
    if (chartData.isEmpty && !_isChartLoading) {
      return Container(
        height: 300,
        child: Center(
            child: Text("Tidak ada data untuk ditampilkan",
                style: TextStyle(color: Colors.white54))),
      );
    }
    return Container(
      height: 300,
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: TextStyle(color: Colors.white54),
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: TextStyle(color: Colors.white54),
          majorGridLines: MajorGridLines(width: 0.5, color: Colors.white24),
          axisLine: AxisLine(width: 0),
        ),
        series: <CartesianSeries>[
          AreaSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.timeLabel,
            yValueMapper: (_ChartData data, _) => data.rsamValue,
            color: Color.fromRGBO(255, 235, 59, 0.2), // Warna area
            borderColor: Colors.yellow,
            borderWidth: 2,
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(255, 235, 59, 0.8),
                Colors.transparent,
              ],
              stops: [0.5, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          )
        ],
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: true),
      ),
    );
  }

  Widget _buildRsamDisplay(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$result',
          style: TextStyle(color: textColor, fontSize: 128),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 27, left: 10),
          child: Text(
            'Rsam',
            style: TextStyle(color: textColor, fontSize: 40),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.timeLabel, this.rsamValue);
  final String timeLabel;
  final double rsamValue;
}
