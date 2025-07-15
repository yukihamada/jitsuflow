import 'package:json_annotation/json_annotation.dart';

part 'member.g.dart';

@JsonSerializable()
class Member {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String role; // user, admin, instructor
  final String status; // active, inactive, suspended
  final String? beltRank; // white, blue, purple, brown, black
  final DateTime? birthDate;
  final int? primaryDojoId;
  final String? primaryDojoName;
  final List<int>? affiliatedDojoIds;
  final String? profileImageUrl;
  final bool hasActiveSubscription;
  final DateTime joinedAt;
  final DateTime? lastLoginAt;
  final DateTime? lastTrainingAt;
  final int totalTrainingSessions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Member({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.status,
    this.beltRank,
    this.birthDate,
    this.primaryDojoId,
    this.primaryDojoName,
    this.affiliatedDojoIds,
    this.profileImageUrl,
    required this.hasActiveSubscription,
    required this.joinedAt,
    this.lastLoginAt,
    this.lastTrainingAt,
    this.totalTrainingSessions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  Map<String, dynamic> toJson() => _$MemberToJson(this);

  Member copyWith({
    int? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? status,
    String? beltRank,
    DateTime? birthDate,
    int? primaryDojoId,
    String? primaryDojoName,
    List<int>? affiliatedDojoIds,
    String? profileImageUrl,
    bool? hasActiveSubscription,
    DateTime? joinedAt,
    DateTime? lastLoginAt,
    DateTime? lastTrainingAt,
    int? totalTrainingSessions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      beltRank: beltRank ?? this.beltRank,
      birthDate: birthDate ?? this.birthDate,
      primaryDojoId: primaryDojoId ?? this.primaryDojoId,
      primaryDojoName: primaryDojoName ?? this.primaryDojoName,
      affiliatedDojoIds: affiliatedDojoIds ?? this.affiliatedDojoIds,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      joinedAt: joinedAt ?? this.joinedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastTrainingAt: lastTrainingAt ?? this.lastTrainingAt,
      totalTrainingSessions: totalTrainingSessions ?? this.totalTrainingSessions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get beltRankDisplay {
    switch (beltRank) {
      case 'white':
        return '白帯';
      case 'blue':
        return '青帯';
      case 'purple':
        return '紫帯';
      case 'brown':
        return '茶帯';
      case 'black':
        return '黒帯';
      default:
        return '未設定';
    }
  }

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'instructor':
        return 'インストラクター';
      case 'user':
        return '一般会員';
      default:
        return role;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'アクティブ';
      case 'inactive':
        return '非アクティブ';
      case 'suspended':
        return '停止中';
      default:
        return status;
    }
  }

  // Training frequency calculation
  String get trainingFrequency {
    if (lastTrainingAt == null) return 'inactive';
    
    final daysSinceLastTraining = DateTime.now().difference(lastTrainingAt!).inDays;
    
    if (daysSinceLastTraining <= 7) {
      return 'active';
    } else if (daysSinceLastTraining <= 14) {
      return 'moderate';
    } else if (daysSinceLastTraining <= 30) {
      return 'low';
    } else {
      return 'inactive';
    }
  }

  String get trainingFrequencyDisplay {
    switch (trainingFrequency) {
      case 'active':
        return '活発';
      case 'moderate':
        return '普通';
      case 'low':
        return '低頻度';
      case 'inactive':
        return '非活動';
      default:
        return '未設定';
    }
  }

  int get daysSinceLastTraining {
    if (lastTrainingAt == null) return 999;
    return DateTime.now().difference(lastTrainingAt!).inDays;
  }
}