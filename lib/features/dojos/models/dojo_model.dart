class DojoModel {
  final String id;
  final String name;
  final String? prefecture;
  final String? city;
  final String? address;
  final String? website;
  final String? phone;
  final String? description;
  final String? photoUrl;
  final int? memberCount;

  const DojoModel({
    required this.id,
    required this.name,
    this.prefecture,
    this.city,
    this.address,
    this.website,
    this.phone,
    this.description,
    this.photoUrl,
    this.memberCount,
  });

  factory DojoModel.fromJson(Map<String, dynamic> j) {
    // Parse "City, Prefecture" from location string
    final location = j['location'] as String?;
    String? pref, city;
    if (location != null) {
      final parts = location.split(',');
      if (parts.length >= 2) {
        city = parts[0].trim();
        pref = parts[1].trim();
      } else {
        pref = location.trim();
      }
    }
    return DojoModel(
      id: j['id']?.toString() ?? '',
      name: j['name_ja'] ?? j['name'] ?? '',
      prefecture: j['prefecture'] ?? pref,
      city: j['city'] ?? city,
      address: j['address'] ?? location,
      website: j['website'],
      phone: j['phone'],
      description: j['description_ja'] ?? j['description'],
      photoUrl: j['logo_url'] ?? j['photo_url'],
      memberCount: j['member_count'],
    );
  }
}
