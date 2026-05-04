import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class FeatureAuthBloc extends Bloc<FeatureAuthEvent, FeatureAuthState> {
  final AuthService _authService;

  FeatureAuthBloc(this._authService) : super(FeatureAuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthMagicLinkRequested>(_onMagicLinkRequested);
    on<AuthVerifyTokenRequested>(_onVerifyTokenRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<FeatureAuthState> emit,
  ) async {
    emit(FeatureAuthLoading());
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      // Token exists but no user object — treat as unauthenticated to force
      // a fresh login so we can hydrate the UserModel properly.
      emit(FeatureAuthUnauthenticated());
    } else {
      emit(FeatureAuthUnauthenticated());
    }
  }

  Future<void> _onMagicLinkRequested(
    AuthMagicLinkRequested event,
    Emitter<FeatureAuthState> emit,
  ) async {
    emit(FeatureAuthLoading());
    try {
      await _authService.sendMagicLink(event.email);
      emit(FeatureAuthMagicLinkSent());
    } catch (e) {
      emit(FeatureAuthError(message: e.toString()));
    }
  }

  Future<void> _onVerifyTokenRequested(
    AuthVerifyTokenRequested event,
    Emitter<FeatureAuthState> emit,
  ) async {
    emit(FeatureAuthLoading());
    try {
      final user = await _authService.verifyToken(event.token);
      if (user != null) {
        emit(FeatureAuthAuthenticated(user: user));
      } else {
        emit(const FeatureAuthError(message: 'トークンの検証に失敗しました'));
      }
    } catch (e) {
      emit(FeatureAuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<FeatureAuthState> emit,
  ) async {
    emit(FeatureAuthLoading());
    try {
      await _authService.logout();
      emit(FeatureAuthUnauthenticated());
    } catch (e) {
      emit(FeatureAuthError(message: e.toString()));
    }
  }
}
