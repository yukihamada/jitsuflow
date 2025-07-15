import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      print('🔐 Attempting login for: ${event.email}');
      final response = await ApiService.login(
        email: event.email,
        password: event.password,
      );
      
      print('📝 Login response: $response');
      final user = User.fromJson(response['user']);
      print('👤 User created: ${user.name}');
      emit(AuthSuccess(user: user, token: response['token']));
    } catch (e) {
      print('❌ Login error: $e');
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final response = await ApiService.register(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
      );
      
      final user = User.fromJson(response['user']);
      emit(AuthSuccess(user: user, token: response['token']));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await ApiService.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if user is already logged in
    // This would typically check stored token and validate it
    emit(AuthInitial());
  }
}