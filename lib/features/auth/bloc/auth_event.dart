part of 'auth_bloc.dart';

abstract class FeatureAuthEvent extends Equatable {
  const FeatureAuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends FeatureAuthEvent {
  const AuthCheckRequested();
}

class AuthMagicLinkRequested extends FeatureAuthEvent {
  final String email;

  const AuthMagicLinkRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthVerifyTokenRequested extends FeatureAuthEvent {
  final String token;

  const AuthVerifyTokenRequested({required this.token});

  @override
  List<Object> get props => [token];
}

class AuthLogoutRequested extends FeatureAuthEvent {
  const AuthLogoutRequested();
}
