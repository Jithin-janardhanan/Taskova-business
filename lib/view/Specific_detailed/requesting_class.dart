

class Driver {
  final int id;
  final String name;
  final String phoneNumber;
  final String address;
  final String? profilePicture;
  final String? preferredAddress;
  final String drivingDuration;
  final double latitude;
  final double longitude;
  double? distance;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.profilePicture,
    this.preferredAddress,
    required this.drivingDuration,
    required this.latitude,
    required this.longitude,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      preferredAddress: json['preferred_working_address'],
      drivingDuration: json['driving_duration'] ?? 'N/A',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
