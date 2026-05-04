class AthleteModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? photoUrl;
  final String? affiliation;
  final String? belt;
  final String? nationality;
  final String? weight;
  final String? bio;

  const AthleteModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.photoUrl,
    this.affiliation,
    this.belt,
    this.nationality,
    this.weight,
    this.bio,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> j) => AthleteModel(
        id: j['id']?.toString() ?? '',
        name: j['display_name'] ?? j['name'] ?? '',
        nameEn: j['name_en'],
        photoUrl: j['avatar_url'] ?? j['photo_url'],
        affiliation: j['home_dojo'] ?? j['affiliation'],
        belt: j['belt'],
        nationality: j['nationality'],
        weight: j['weight_class'],
        bio: j['bio_ja'] ?? j['bio'],
      );
}
