class Hospital {
  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.mapImageUrl,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String? mapImageUrl;

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      mapImageUrl: json['map_image_url']?.toString(),
    );
  }
}