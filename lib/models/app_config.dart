class AppConfig {
  final bool adsEnabled;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? minVersion;
  final Map<String, dynamic> extra;

  const AppConfig({
    this.adsEnabled = false,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.minVersion,
    this.extra = const {},
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      adsEnabled: json['ads_enabled'] as bool? ?? false,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String?,
      minVersion: json['min_version'] as String?,
      extra: json['extra'] is Map
          ? Map<String, dynamic>.from(json['extra'] as Map)
          : {},
    );
  }
}
