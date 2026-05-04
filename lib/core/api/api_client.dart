import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/videos/models/video_model.dart';
import '../../features/news/models/news_model.dart';
import '../../features/dojos/models/dojo_model.dart';
import '../../features/athletes/models/athlete_model.dart';
import '../../features/community/models/forum_models.dart';
import '../../features/instructor/models/course_model.dart';

class ApiClient {
  static const String baseUrl = 'https://jiuflow-ssr.fly.dev';
  static Dio? _sharedDio;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  /// Called when 401 received — app should redirect to login
  static void Function()? onUnauthorized;

  ApiClient() {
    if (_sharedDio != null) { _dio = _sharedDio!; return; }
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('[API] 401 Unauthorized — redirecting to login');
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
    _sharedDio = dio;
    _dio = dio;
  }

  Dio get dio => _dio;

  Future<List<VideoModel>> fetchVideos() async {
    try {
      final res = await _dio.get('/api/v1/videos');
      final list = (res.data['videos'] as List?) ?? [];
      return list.map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchVideos error: $e');
      return [];
    }
  }

  Future<List<NewsModel>> fetchNews() async {
    try {
      final res = await _dio.get('/api/v1/news');
      final list = (res.data['news'] as List?) ?? [];
      return list.map((e) => NewsModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchNews error: $e');
      return [];
    }
  }

  Future<List<DojoModel>> fetchDojos() async {
    try {
      final res = await _dio.get('/api/v1/dojos');
      final list = (res.data['dojos'] as List?) ?? [];
      return list.map((e) => DojoModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchDojos error: $e');
      return [];
    }
  }

  Future<List<AthleteModel>> fetchAthletes() async {
    try {
      final res = await _dio.get('/api/v1/athletes');
      final list = (res.data['athletes'] as List?) ?? [];
      return list.map((e) => AthleteModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchAthletes error: $e');
      return [];
    }
  }

  Future<List<ForumThread>> fetchForumThreads() async {
    try {
      final res = await _dio.get('/api/v1/forum/threads');
      final list = (res.data['threads'] as List?) ?? [];
      return list.map((e) => ForumThread.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchForumThreads error: $e');
      return [];
    }
  }

  Future<List<CourseModel>> fetchInstructors() async {
    try {
      final res = await _dio.get('/api/v1/instructors');
      final list = (res.data['courses'] as List?) ?? [];
      return list.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[API] fetchInstructors error: $e');
      return [];
    }
  }

  /// Returns the created thread id on success, null on failure.
  Future<String?> createForumThread({
    required String title,
    required String body,
    required String category,
  }) async {
    try {
      final res = await _dio.post('/api/v1/forum/threads', data: {
        'title': title,
        'body': body,
        'category': category,
      });
      return res.data['id'] as String?;
    } catch (e) {
      debugPrint('[API] createForumThread error: $e');
      return null;
    }
  }

  /// Check user's subscription status
  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      final res = await _dio.get('/api/v1/subscription');
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[API] getSubscription error: $e');
      return null;
    }
  }

  /// Create Stripe checkout session, returns {url, session_id}
  Future<String?> createCheckoutSession({String? priceId}) async {
    try {
      final res = await _dio.post('/api/v1/subscription/checkout', data: {
        if (priceId != null) 'price_id': priceId,
      });
      return res.data['url'] as String?;
    } catch (e) {
      debugPrint('[API] createCheckoutSession error: $e');
      return null;
    }
  }
}
