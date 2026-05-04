part of 'auth_bloc.dart';

abstract class FeatureAuthState extends Equatable {
  const FeatureAuthState();

  @override
  List<Object?> get props => [];
}

class FeatureAuthInitial extends FeatureAuthState {}

class FeatureAuthLoading extends FeatureAuthState {}

class FeatureAuthAuthenticated extends FeatureAuthState {
  final UserModel user;

  const FeatureAuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user.id];
}

class FeatureAuthUnauthenticated extends FeatureAuthState {}

class FeatureAuthMagicLinkSent extends FeatureAuthState {}

class FeatureAuthError extends FeatureAuthState {
  final String message;

  const FeatureAuthError({required this.message});

  @override
  List<Object> get props => [message];
}
