import 'package:json_annotation/json_annotation.dart';

part 'dojo.g.dart';

@JsonSerializable()
class Dojo {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? description;
  final int maxCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dojo({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.description,
    required this.maxCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dojo.fromJson(Map<String, dynamic> json) => _$DojoFromJson(json);

  Map<String, dynamic> toJson() => _$DojoToJson(this);

  Dojo copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? description,
    int? maxCapacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dojo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}