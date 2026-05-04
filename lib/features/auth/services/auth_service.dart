import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  AuthService(this._api);

  // Magic link: POST /auth/magic (form-encoded — server expects Form)
  Future<void> sendMagicLink(String email) async {
    await _api.dio.post(
      '/auth/magic',
      data: {'email': email},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // Verify token from deep link: GET /api/auth/magic/verify?token=xxx
  Future<UserModel?> verifyToken(String token) async {
    try {
      final res = await _api.dio
          .get('/api/auth/magic/verify', queryParameters: {'token': token});
      if (res.statusCode == 200 && res.data != null) {
        final authToken = res.data['token'] as String?;
        if (authToken != null) {
          await _storage.write(key: 'auth_token', value: authToken);
          return UserModel.fromJson(res.data['user'] ?? res.data);
        }
      }
    } catch (e) {
      debugPrint('[Auth] verifyToken error: $e');
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
