class AlertSettingModel {
  AlertSettingModel({
    required this.safeZoneAlerted,
    required this.highHeartRateAlert,
    required this.soSenableAlert,
  });

  final bool safeZoneAlerted;
  final bool highHeartRateAlert;
  final bool soSenableAlert;

  factory AlertSettingModel.fromJson(Map<String, dynamic> json) {
    return AlertSettingModel(
      safeZoneAlerted: _requireBool(json['safeZoneAlerted'], 'safeZoneAlerted'),
      highHeartRateAlert:
          _requireBool(json['highHeartRateAlert'], 'highHeartRateAlert'),
      soSenableAlert: _requireBool(json['soSenableAlert'], 'soSenableAlert'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'safeZoneAlerted': safeZoneAlerted,
      'highHeartRateAlert': highHeartRateAlert,
      'soSenableAlert': soSenableAlert,
    };
  }

  static bool _requireBool(dynamic value, String fieldName) {
    if (value is bool) {
      return value;
    }

    throw FormatException(
      'Alert setting field "$fieldName" is missing or invalid.',
    );
  }
}
