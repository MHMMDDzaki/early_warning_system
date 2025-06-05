class ModelDrive {
  final int triggerOn;
  final int triggerOff;
  final String? audioUrl;
  final String? audioName;

  ModelDrive(
      {required this.triggerOn, required this.triggerOff, this.audioUrl, this.audioName});

  factory ModelDrive.fromMap(Map<String, dynamic> data) {
    return ModelDrive(
      triggerOn: data['trigger_on'] ?? 1000,
      triggerOff: data['trigger_off'] ?? 300,
      audioUrl: data['audio_url'],
      audioName: data['audio_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trigger_on': triggerOn,
      'trigger_off': triggerOff,
      if (audioUrl != null) 'audio_url': audioUrl, // Only include if not null
      if (audioName != null) 'audio_name': audioName, // Only include if not null
    };
  }
}
