class SafeZoneModel {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? radius;

  SafeZoneModel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radius,
  });
}
