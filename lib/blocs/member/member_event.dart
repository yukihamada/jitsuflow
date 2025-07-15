part of 'member_bloc.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class MemberLoadRequested extends MemberEvent {
  const MemberLoadRequested();
}

class MemberCreateRequested extends MemberEvent {
  final String email;
  final String name;
  final String? phone;
  final String role;
  final String? beltRank;
  final int? primaryDojoId;

  const MemberCreateRequested({
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.beltRank,
    this.primaryDojoId,
  });

  @override
  List<Object?> get props => [email, name, phone, role, beltRank, primaryDojoId];
}

class MemberUpdateRequested extends MemberEvent {
  final int memberId;
  final String? name;
  final String? phone;
  final String? beltRank;
  final int? primaryDojoId;

  const MemberUpdateRequested({
    required this.memberId,
    this.name,
    this.phone,
    this.beltRank,
    this.primaryDojoId,
  });

  @override
  List<Object?> get props => [memberId, name, phone, beltRank, primaryDojoId];
}

class MemberDeleteRequested extends MemberEvent {
  final int memberId;

  const MemberDeleteRequested({
    required this.memberId,
  });

  @override
  List<Object?> get props => [memberId];
}

class MemberFilterRequested extends MemberEvent {
  final String? role;
  final String? status;
  final String? beltRank;
  final int? dojoId;
  final String? searchQuery;

  const MemberFilterRequested({
    this.role,
    this.status,
    this.beltRank,
    this.dojoId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [role, status, beltRank, dojoId, searchQuery];
}

class MemberRoleChangeRequested extends MemberEvent {
  final int memberId;
  final String newRole;

  const MemberRoleChangeRequested({
    required this.memberId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [memberId, newRole];
}

class MemberStatusChangeRequested extends MemberEvent {
  final int memberId;
  final String newStatus;

  const MemberStatusChangeRequested({
    required this.memberId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [memberId, newStatus];
}