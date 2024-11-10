class ModelAlarm {
 String message;
 String timestamp;

 ModelAlarm({required this.message, required this.timestamp});

 factory ModelAlarm.fromJson(Map<String, dynamic> json) {
   return ModelAlarm(
     message: json['message'],
     timestamp: json['timestamp']
   );
 }
}