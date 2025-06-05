class ModelAlarm {
  final String timestamp;
  final double rsamValue;

  ModelAlarm({
    required this.timestamp,
    required this.rsamValue,
  });

  factory ModelAlarm.fromJson(Map<String, dynamic> json) {
    return ModelAlarm(
      timestamp: json['Timestamp'] ?? '',
      rsamValue: (json['RSAM'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => '$timestamp,${rsamValue.toStringAsFixed(2)}';
}