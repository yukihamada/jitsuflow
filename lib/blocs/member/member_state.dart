part of 'member_bloc.dart';

abstract class MemberState extends Equatable {
  const MemberState();

  @override
  List<Object> get props => [];
}

class MemberInitial extends MemberState {}

class MemberLoading extends MemberState {}

class MemberLoadSuccess extends MemberState {
  final List<Member> members;

  const MemberLoadSuccess({
    required this.members,
  });

  @override
  List<Object> get props => [members];
}

class MemberCreateSuccess extends MemberState {}

class MemberUpdateSuccess extends MemberState {}

class MemberDeleteSuccess extends MemberState {}

class MemberFailure extends MemberState {
  final String message;

  const MemberFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}