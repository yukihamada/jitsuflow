import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/member.dart';

part 'member_event.dart';
part 'member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  MemberBloc() : super(MemberInitial()) {
    on<MemberLoadRequested>(_onLoadRequested);
    on<MemberCreateRequested>(_onCreateRequested);
    on<MemberUpdateRequested>(_onUpdateRequested);
    on<MemberDeleteRequested>(_onDeleteRequested);
    on<MemberFilterRequested>(_onFilterRequested);
    on<MemberRoleChangeRequested>(_onRoleChangeRequested);
    on<MemberStatusChangeRequested>(_onStatusChangeRequested);
  }

  List<Member> _allMembers = [];

  Future<void> _onLoadRequested(
    MemberLoadRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      final members = await ApiService.getMembers();
      _allMembers = members;
      emit(MemberLoadSuccess(members: members));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    MemberCreateRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      final member = await ApiService.createMember(
        email: event.email,
        name: event.name,
        phone: event.phone,
        role: event.role,
        beltRank: event.beltRank,
        primaryDojoId: event.primaryDojoId,
      );
      
      _allMembers.insert(0, member);
      emit(MemberCreateSuccess());
      emit(MemberLoadSuccess(members: _allMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    MemberUpdateRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      final updatedMember = await ApiService.updateMember(
        memberId: event.memberId,
        name: event.name,
        phone: event.phone,
        beltRank: event.beltRank,
        primaryDojoId: event.primaryDojoId,
      );
      
      final index = _allMembers.indexWhere((m) => m.id == event.memberId);
      if (index != -1) {
        _allMembers[index] = updatedMember;
      }
      
      emit(MemberUpdateSuccess());
      emit(MemberLoadSuccess(members: _allMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    MemberDeleteRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      await ApiService.deleteMember(event.memberId);
      _allMembers.removeWhere((m) => m.id == event.memberId);
      emit(MemberDeleteSuccess());
      emit(MemberLoadSuccess(members: _allMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onFilterRequested(
    MemberFilterRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      List<Member> filteredMembers = _allMembers;
      
      // Apply filters
      if (event.role != null) {
        filteredMembers = filteredMembers.where((m) => m.role == event.role).toList();
      }
      
      if (event.status != null) {
        filteredMembers = filteredMembers.where((m) => m.status == event.status).toList();
      }
      
      if (event.beltRank != null) {
        filteredMembers = filteredMembers.where((m) => m.beltRank == event.beltRank).toList();
      }
      
      if (event.dojoId != null) {
        filteredMembers = filteredMembers.where((m) => 
          m.primaryDojoId == event.dojoId || 
          (m.affiliatedDojoIds?.contains(event.dojoId) ?? false)
        ).toList();
      }
      
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filteredMembers = filteredMembers.where((m) =>
          m.name.toLowerCase().contains(query) ||
          m.email.toLowerCase().contains(query) ||
          (m.phone?.contains(query) ?? false)
        ).toList();
      }
      
      emit(MemberLoadSuccess(members: filteredMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onRoleChangeRequested(
    MemberRoleChangeRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      await ApiService.changeMemberRole(event.memberId, event.newRole);
      
      final index = _allMembers.indexWhere((m) => m.id == event.memberId);
      if (index != -1) {
        _allMembers[index] = _allMembers[index].copyWith(role: event.newRole);
      }
      
      emit(MemberUpdateSuccess());
      emit(MemberLoadSuccess(members: _allMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }

  Future<void> _onStatusChangeRequested(
    MemberStatusChangeRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    
    try {
      await ApiService.changeMemberStatus(event.memberId, event.newStatus);
      
      final index = _allMembers.indexWhere((m) => m.id == event.memberId);
      if (index != -1) {
        _allMembers[index] = _allMembers[index].copyWith(status: event.newStatus);
      }
      
      emit(MemberUpdateSuccess());
      emit(MemberLoadSuccess(members: _allMembers));
    } catch (e) {
      emit(MemberFailure(message: e.toString()));
    }
  }
}