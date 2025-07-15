import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/video.dart';
import '../models/dojo.dart';
import '../models/member.dart';
import '../models/rental.dart';
import '../models/payment.dart';
import '../models/revenue_summary.dart';
import '../models/instructor_assignment.dart';
import '../models/product.dart';

class ApiService {
  static const String _baseUrl = 'https://api.jitsuflow.app/api';
  static const String _tokenKey = 'auth_token';
  
  // インスタンスメソッドとして追加
  Future<int> getCurrentUserId() async {
    // TODO: 実際の実装では認証情報から取得
    return 1; // デモ用のユーザーID
  }
  
  Future<String?> _getTokenInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Map<String, String> _getHeadersInstance([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // 汎用HTTPメソッド
  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await _getTokenInstance();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _getHeadersInstance(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getTokenInstance();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _getHeadersInstance(token),
      body: jsonEncode(body),
    );
    
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }
  
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _getTokenInstance();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _getHeadersInstance(token),
    );
    
    if (response.statusCode == 200) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } else {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Map<String, String> _getHeaders([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Authentication
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // Demo mode - simulate successful registration
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate network delay
    
    // Check for duplicate email (demo validation)
    if (email == 'user@jitsuflow.app' || email == 'admin@jitsuflow.app') {
      throw Exception('このメールアドレスは既に使用されています');
    }
    
    final demoToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    await _saveToken(demoToken);
    
    return {
      'message': 'Registration successful',
      'user': {
        'id': DateTime.now().millisecondsSinceEpoch % 10000,
        'email': email,
        'name': name,
        'phone': phone,
        'stripeCustomerId': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      'token': demoToken,
    };

    // Real implementation would be:
    /*
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
    */
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Demo mode - simulate successful login for demo accounts
    if (email == 'user@jitsuflow.app' || email == 'admin@jitsuflow.app') {
      final isAdmin = email == 'admin@jitsuflow.app';
      final demoToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      
      await _saveToken(demoToken);
      
      return {
        'message': 'Login successful',
        'user': {
          'id': isAdmin ? 999 : 1,
          'email': email,
          'name': isAdmin ? '管理者' : 'デモユーザー',
          'phone': null,
          'stripeCustomerId': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        'token': demoToken,
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  static Future<void> logout() async {
    await _removeToken();
  }

  // Bookings
  static Future<List<Booking>> getBookings() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample bookings
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      return [
        Booking(
          id: 1,
          userId: 1,
          dojoId: 1,
          classType: 'ベーシック',
          bookingDate: DateTime.now().add(const Duration(days: 1)),
          bookingTime: '19:00',
          status: 'confirmed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Booking(
          id: 2,
          userId: 1,
          dojoId: 2,
          classType: 'アドバンス',
          bookingDate: DateTime.now().add(const Duration(days: 3)),
          bookingTime: '20:00',
          status: 'confirmed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Booking(
          id: 3,
          userId: 1,
          dojoId: 1,
          classType: 'コンペティション',
          bookingDate: DateTime.now().add(const Duration(days: 7)),
          bookingTime: '18:30',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/dojo/bookings'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['bookings'] as List)
          .map((booking) => Booking.fromJson(booking))
          .toList();
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  static Future<Booking> createBooking({
    required int dojoId,
    required String classType,
    required DateTime bookingDate,
    required String bookingTime,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/dojo/bookings'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'dojo_id': dojoId,
        'class_type': classType,
        'booking_date': bookingDate.toIso8601String().split('T')[0],
        'booking_time': bookingTime,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201) {
      return Booking.fromJson(data['booking']);
    } else {
      throw Exception(data['message'] ?? 'Failed to create booking');
    }
  }

  static Future<Map<String, dynamic>> getAvailability({
    required int dojoId,
    required DateTime date,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/dojo/availability?dojo_id=$dojoId&date=${date.toIso8601String().split('T')[0]}'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load availability');
    }
  }

  // Videos
  static Future<List<Video>> getVideos({bool? premium}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Try API first, fallback to demo data if it fails
    try {
      final uri = premium != null 
          ? Uri.parse('$_baseUrl/videos?premium=$premium')
          : Uri.parse('$_baseUrl/videos');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['videos'] as List)
            .map((video) => Video.fromJson(video))
            .toList();
      }
    } catch (e) {
      print('API Error: $e, using fallback data');
    }
    
    // Fallback to demo data
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      
      final allVideos = [
        // Free Basic Content
        Video(
          id: 'video-1',
          title: '【初心者必見】クローズドガードの基本',
          description: '柔術の基本中の基本、クローズドガードの正しいポジションと基本的な動きを村田良蔵が詳しく解説。初心者が最初に覚えるべき重要なポジションです。',
          isPremium: false,
          category: 'basics',
          uploadUrl: 'https://example.com/basic-closed-guard.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 780, // 13 minutes
          views: 2453,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Video(
          id: 'video-2',
          title: '柔術の基本エチケットとマナー',
          description: '道場での基本的なエチケットと礼儀作法について。初心者が知っておくべき柔術コミュニティでのマナーを解説します。',
          isPremium: false,
          category: 'basics',
          uploadUrl: 'https://example.com/etiquette.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 420, // 7 minutes
          views: 1876,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        Video(
          id: 'video-3',
          title: 'パスガードの基本動作',
          description: '相手のガードを通過するための基本的な考え方と動作。廣鰭翔大が実演する効果的なパスガードテクニック。',
          isPremium: false,
          category: 'basics',
          uploadUrl: 'https://example.com/guard-pass-basic.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 920, // 15.3 minutes
          views: 3241,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        
        // Premium Advanced Content
        Video(
          id: 'video-4',
          title: '【プレミアム】ベリンボロシステム完全解説',
          description: '現代柔術の代表的なテクニック、ベリンボロの基本から応用まで徹底解説。村田良蔵の実戦経験を基にした実用的なアプローチ。',
          isPremium: true,
          category: 'advanced',
          uploadUrl: 'https://example.com/berimbolo-system.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 1620, // 27 minutes
          views: 892,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        Video(
          id: 'video-5',
          title: '【プレミアム】ラペラガードマスタークラス',
          description: '諸澤陽斗によるラペラガードの高度なテクニック集。JBJJF全日本選手権優勝者の技術を学ぶプレミアムコンテンツ。',
          isPremium: true,
          category: 'advanced',
          uploadUrl: 'https://example.com/lapel-guard.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 1980, // 33 minutes
          views: 645,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          updatedAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
        Video(
          id: 'video-6',
          title: '【プレミアム】サブミッション連携システム',
          description: '実戦で使える効果的なサブミッション連携。一つの動きから複数のサブミッションへ繋げる高度なテクニック。',
          isPremium: true,
          category: 'submissions',
          uploadUrl: 'https://example.com/sub-chains.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 2100, // 35 minutes
          views: 723,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        
        // Competition Content
        Video(
          id: 'video-7',
          title: '試合で勝つためのメンタル準備',
          description: '世界選手権優勝者村田良蔵による試合前の心構えとメンタル準備法。試合で実力を発揮するためのコツ。',
          isPremium: false,
          category: 'competition',
          uploadUrl: 'https://example.com/comp-mental.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 540, // 9 minutes
          views: 1987,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Video(
          id: 'video-8',
          title: '【プレミアム】試合戦術とゲームプラン',
          description: '試合での具体的な戦術とゲームプランの立て方。相手のタイプ別対策と効果的なポイント戦略。',
          isPremium: true,
          category: 'competition',
          uploadUrl: 'https://example.com/game-plan.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 1440, // 24 minutes
          views: 567,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        
        // Special Content
        Video(
          id: 'video-9',
          title: '女性のための柔術テクニック',
          description: '女性特有の体型と筋力を活かした効果的な柔術テクニック。初心者女性にも分かりやすく解説。',
          isPremium: false,
          category: 'basics',
          uploadUrl: 'https://example.com/women-bjj.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 720, // 12 minutes
          views: 1432,
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Video(
          id: 'video-10',
          title: '【プレミアム】マスター技術解説シリーズ',
          description: '黒帯マスターによる高度な技術解説。細かなディテールと実戦での応用法まで詳しく解説。',
          isPremium: true,
          category: 'advanced',
          uploadUrl: 'https://example.com/master-series.mp4',
          thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          duration: 2520, // 42 minutes
          views: 398,
          status: 'published',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      if (premium != null) {
        return allVideos.where((video) => video.isPremium == premium).toList();
      }
      return allVideos;
  }

  static Future<Video> getVideo(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/videos/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Video.fromJson(data['video']);
    } else {
      throw Exception('Failed to load video');
    }
  }

  // Payments
  static Future<Map<String, dynamic>> createSubscription({
    required String priceId,
    required String paymentMethodId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/payments/create-subscription'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'price_id': priceId,
        'payment_method_id': paymentMethodId,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create subscription');
    }
  }

  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/payments/subscription'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load subscription status');
    }
  }

  static Future<void> cancelSubscription() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/payments/cancel-subscription'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to cancel subscription');
    }
  }

  // Dojos
  static Future<List<Map<String, dynamic>>> getDojos() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample dojos
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {
          'id': 1,
          'name': 'YAWARA JIU-JITSU ACADEMY',
          'address': '東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F',
          'instructor': 'Ryozo Murata (村田良蔵)',
          'pricing_info': 'なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月',
        },
        {
          'id': 2,
          'name': 'Over Limit Sapporo',
          'address': '北海道札幌市中央区南4条西1丁目15-2 栗林ビル3F',
          'instructor': 'Ryozo Murata',
          'pricing_info': 'フルタイム¥12,000/月、マンスリー5¥10,000/月、レディース&キッズ¥8,000/月',
        },
        {
          'id': 3,
          'name': 'スイープ',
          'address': '東京都渋谷区千駄ヶ谷3-55-12 ヴィラパルテノン3F',
          'instructor': 'スイープインストラクター',
          'pricing_info': '月8回プラン¥22,000/月、通い放題プラン¥33,000/月',
        },
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/dojos'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['dojos']);
    } else {
      throw Exception('Failed to load dojos');
    }
  }

  // Schedules
  static Future<List<Map<String, dynamic>>> getSchedules({
    String? dojoId,
    String? instructor,
    String? level,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample schedules
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      final now = DateTime.now();
      final allSchedules = [
        {
          'id': 1,
          'day': '月',
          'date': '${now.day}',
          'className': 'ベーシッククラス',
          'time': '19:00-20:30',
          'instructor': '村田良蔵',
          'level': '初級',
          'capacity': 20,
          'booked': 15,
          'available': true,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 2,
          'day': '火',
          'date': '${now.day + 1}',
          'className': 'アドバンスクラス',
          'time': '19:00-20:30',
          'instructor': '諸澤陽斗',
          'level': '上級',
          'capacity': 15,
          'booked': 12,
          'available': true,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 3,
          'day': '水',
          'date': '${now.day + 2}',
          'className': 'オープンクラス',
          'time': '19:00-20:30',
          'instructor': '佐藤正幸',
          'level': '全レベル',
          'capacity': 25,
          'booked': 20,
          'available': true,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 4,
          'day': '木',
          'date': '${now.day + 3}',
          'className': 'レディースクラス',
          'time': '19:00-20:30',
          'instructor': '堰本祐希',
          'level': '女性限定',
          'capacity': 15,
          'booked': 15,
          'available': false,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 5,
          'day': '金',
          'date': '${now.day + 4}',
          'className': 'コンペティションクラス',
          'time': '19:00-20:30',
          'instructor': '村田良蔵',
          'level': '試合向け',
          'capacity': 12,
          'booked': 8,
          'available': true,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 6,
          'day': '土',
          'date': '${now.day + 5}',
          'className': 'キッズクラス',
          'time': '14:00-15:30',
          'instructor': '立石修也',
          'level': '子供向け',
          'capacity': 20,
          'booked': 16,
          'available': true,
          'dojo_id': 2,
          'dojo_name': 'Over Limit Sapporo',
        },
        {
          'id': 7,
          'day': '月',
          'date': '${now.day}',
          'className': 'ベーシッククラス',
          'time': '20:00-21:30',
          'instructor': '廣鰭翔大',
          'level': '初級',
          'capacity': 15,
          'booked': 8,
          'available': true,
          'dojo_id': 3,
          'dojo_name': 'スイープ',
        },
        {
          'id': 8,
          'day': '火',
          'date': '${now.day + 1}',
          'className': 'テクニッククラス',
          'time': '20:00-21:30',
          'instructor': '村田良蔵',
          'level': '中級',
          'capacity': 15,
          'booked': 10,
          'available': true,
          'dojo_id': 3,
          'dojo_name': 'スイープ',
        },
        {
          'id': 9,
          'day': '水',
          'date': '${now.day + 2}',
          'className': 'YAWARAフルタイムクラス',
          'time': '19:00-20:30',
          'instructor': '村田良蔵',
          'level': '全レベル',
          'capacity': 25,
          'booked': 18,
          'available': true,
          'dojo_id': 1,
          'dojo_name': 'YAWARA JIU-JITSU ACADEMY',
        },
        {
          'id': 10,
          'day': '木',
          'date': '${now.day + 3}',
          'className': 'なでしこクラス',
          'time': '18:00-19:30',
          'instructor': '濱田真亮',
          'level': '女性限定',
          'capacity': 12,
          'booked': 9,
          'available': true,
          'dojo_id': 1,
          'dojo_name': 'YAWARA JIU-JITSU ACADEMY',
        },
      ];

      // Apply filters
      var filteredSchedules = allSchedules.where((schedule) {
        if (dojoId != null && schedule['dojo_id'].toString() != dojoId) {
          return false;
        }
        if (instructor != null && !schedule['instructor'].toString().toLowerCase().contains(instructor.toLowerCase())) {
          return false;
        }
        if (level != null && schedule['level'].toString() != level) {
          return false;
        }
        return true;
      }).toList();

      return filteredSchedules;
    }

    final queryParams = <String, String>{};
    if (dojoId != null) queryParams['dojo_id'] = dojoId;
    if (instructor != null) queryParams['instructor'] = instructor;
    if (level != null) queryParams['level'] = level;

    final uri = Uri.parse('$_baseUrl/schedules').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['schedules']);
    } else {
      throw Exception('Failed to load schedules');
    }
  }

  // Multiple bookings
  static Future<bool> createMultipleBookings(List<int> scheduleIds) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - simulate success
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/bookings/multiple'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'schedule_ids': scheduleIds,
        'user_id': 1,
      }),
    );

    return response.statusCode == 201;
  }

  // Teams
  static Future<List<Map<String, dynamic>>> getUserTeams({int? userId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample teams
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        {
          'id': 1,
          'name': 'YAWARA競技チーム',
          'description': 'YAWARA道場の競技志向チーム',
          'dojo_id': 1,
          'dojo_name': 'YAWARA JIU-JITSU ACADEMY',
          'role': 'admin',
          'membership_status': 'active',
        },
        {
          'id': 2,
          'name': 'スイープ初心者の会',
          'description': 'スイープ道場の初心者向けチーム',
          'dojo_id': 3,
          'dojo_name': 'スイープ',
          'role': 'member',
          'membership_status': 'active',
        },
      ];
    }

    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId.toString();

    final uri = Uri.parse('$_baseUrl/teams').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['teams']);
    } else {
      throw Exception('Failed to load teams');
    }
  }

  static Future<bool> createTeam({
    required String name,
    required String description,
    required int dojoId,
    int? createdBy,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - simulate success
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/teams'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'name': name,
        'description': description,
        'dojo_id': dojoId,
        'created_by': createdBy ?? 1,
      }),
    );

    return response.statusCode == 201;
  }

  // Affiliations
  static Future<List<Map<String, dynamic>>> getUserAffiliations({int? userId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample affiliations
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 350));
      return [
        {
          'id': 1,
          'user_id': 1,
          'dojo_id': 1,
          'name': 'YAWARA JIU-JITSU ACADEMY',
          'address': '東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F',
          'instructor': 'Ryozo Murata (村田良蔵)',
          'pricing_info': 'なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月',
          'is_primary': true,
          'joined_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
        {
          'id': 2,
          'user_id': 1,
          'dojo_id': 3,
          'name': 'スイープ',
          'address': '東京都渋谷区千駄ヶ谷3-55-12 ヴィラパルテノン3F',
          'instructor': 'スイープインストラクター',
          'pricing_info': '月8回プラン¥22,000/月、通い放題プラン¥33,000/月',
          'is_primary': false,
          'joined_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        },
      ];
    }

    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId.toString();

    final uri = Uri.parse('$_baseUrl/affiliations').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['affiliations']);
    } else {
      throw Exception('Failed to load affiliations');
    }
  }

  static Future<bool> addDojoAffiliation({
    required int dojoId,
    bool isPrimary = false,
    int? userId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - simulate success
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 700));
      return true;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/affiliations'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'user_id': userId ?? 1,
        'dojo_id': dojoId,
        'is_primary': isPrimary,
      }),
    );

    return response.statusCode == 201;
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API health check failed');
    }
  }

  // Members management
  static Future<List<Member>> getMembers() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample members with enhanced training data
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        Member(
          id: 1,
          email: 'user@jitsuflow.app',
          name: 'デモユーザー',
          phone: '090-1234-5678',
          role: 'user',
          status: 'active',
          beltRank: 'blue',
          primaryDojoId: 1,
          primaryDojoName: 'YAWARA JIU-JITSU ACADEMY',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 90)),
          lastLoginAt: DateTime.now(),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 2)),
          totalTrainingSessions: 45,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 2,
          email: 'instructor@jitsuflow.app',
          name: 'インストラクター太郎',
          role: 'instructor',
          status: 'active',
          beltRank: 'black',
          primaryDojoId: 1,
          primaryDojoName: 'YAWARA JIU-JITSU ACADEMY',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 365)),
          lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 1)),
          totalTrainingSessions: 180,
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 3,
          email: 'member1@jitsuflow.app',
          name: '山田花子',
          phone: '080-9876-5432',
          role: 'user',
          status: 'active',
          beltRank: 'white',
          primaryDojoId: 2,
          primaryDojoName: 'Over Limit Sapporo',
          hasActiveSubscription: false,
          joinedAt: DateTime.now().subtract(const Duration(days: 30)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 7)),
          totalTrainingSessions: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 4,
          email: 'member2@jitsuflow.app',
          name: '鈴木次郎',
          role: 'user',
          status: 'inactive',
          beltRank: 'purple',
          primaryDojoId: 3,
          primaryDojoName: 'スイープ',
          hasActiveSubscription: false,
          joinedAt: DateTime.now().subtract(const Duration(days: 180)),
          lastLoginAt: DateTime.now().subtract(const Duration(days: 60)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 45)),
          totalTrainingSessions: 85,
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 5,
          email: 'tanaka@jitsuflow.app',
          name: '田中健一',
          phone: '090-3456-7890',
          role: 'user',
          status: 'active',
          beltRank: 'blue',
          primaryDojoId: 1,
          primaryDojoName: 'YAWARA JIU-JITSU ACADEMY',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 200)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 3)),
          totalTrainingSessions: 95,
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 6,
          email: 'sato@jitsuflow.app',
          name: '佐藤美咲',
          phone: '080-2468-1357',
          role: 'user',
          status: 'active',
          beltRank: 'white',
          primaryDojoId: 2,
          primaryDojoName: 'Over Limit Sapporo',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 45)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 1)),
          totalTrainingSessions: 22,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 7,
          email: 'kato@jitsuflow.app',
          name: '加藤雄大',
          role: 'user',
          status: 'active',
          beltRank: 'purple',
          primaryDojoId: 3,
          primaryDojoName: 'スイープ',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 300)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 5)),
          totalTrainingSessions: 125,
          createdAt: DateTime.now().subtract(const Duration(days: 300)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 8,
          email: 'nakamura@jitsuflow.app',
          name: '中村聡子',
          phone: '090-8765-4321',
          role: 'user',
          status: 'active',
          beltRank: 'blue',
          primaryDojoId: 1,
          primaryDojoName: 'YAWARA JIU-JITSU ACADEMY',
          hasActiveSubscription: false,
          joinedAt: DateTime.now().subtract(const Duration(days: 150)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 14)),
          totalTrainingSessions: 60,
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 9,
          email: 'ito@jitsuflow.app',
          name: '伊藤大輔',
          role: 'user',
          status: 'active',
          beltRank: 'brown',
          primaryDojoId: 2,
          primaryDojoName: 'Over Limit Sapporo',
          hasActiveSubscription: true,
          joinedAt: DateTime.now().subtract(const Duration(days: 500)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 1)),
          totalTrainingSessions: 250,
          createdAt: DateTime.now().subtract(const Duration(days: 500)),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 10,
          email: 'watanabe@jitsuflow.app',
          name: '渡辺真理',
          phone: '080-1357-2468',
          role: 'user',
          status: 'inactive',
          beltRank: 'white',
          primaryDojoId: 3,
          primaryDojoName: 'スイープ',
          hasActiveSubscription: false,
          joinedAt: DateTime.now().subtract(const Duration(days: 80)),
          lastTrainingAt: DateTime.now().subtract(const Duration(days: 35)),
          totalTrainingSessions: 8,
          createdAt: DateTime.now().subtract(const Duration(days: 80)),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/members'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['members'] as List)
          .map((member) => Member.fromJson(member))
          .toList();
    } else {
      throw Exception('Failed to load members');
    }
  }

  static Future<Member> createMember({
    required String email,
    required String name,
    String? phone,
    required String role,
    String? beltRank,
    int? primaryDojoId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 800));
      return Member(
        id: DateTime.now().millisecondsSinceEpoch,
        email: email,
        name: name,
        phone: phone,
        role: role,
        status: 'active',
        beltRank: beltRank,
        primaryDojoId: primaryDojoId,
        hasActiveSubscription: false,
        joinedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/members'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'belt_rank': beltRank,
        'primary_dojo_id': primaryDojoId,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 201) {
      return Member.fromJson(data['member']);
    } else {
      throw Exception(data['message'] ?? 'Failed to create member');
    }
  }

  static Future<Member> updateMember({
    required int memberId,
    String? name,
    String? phone,
    String? beltRank,
    int? primaryDojoId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 600));
      // Return dummy updated member
      return Member(
        id: memberId,
        email: 'updated@jitsuflow.app',
        name: name ?? 'Updated User',
        phone: phone,
        role: 'user',
        status: 'active',
        beltRank: beltRank,
        primaryDojoId: primaryDojoId,
        hasActiveSubscription: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/members/$memberId'),
      headers: _getHeaders(token),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (beltRank != null) 'belt_rank': beltRank,
        if (primaryDojoId != null) 'primary_dojo_id': primaryDojoId,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return Member.fromJson(data['member']);
    } else {
      throw Exception(data['message'] ?? 'Failed to update member');
    }
  }

  static Future<void> deleteMember(int memberId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/members/$memberId'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete member');
    }
  }

  static Future<void> changeMemberRole(int memberId, String newRole) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/members/$memberId/role'),
      headers: _getHeaders(token),
      body: jsonEncode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to change role');
    }
  }

  static Future<void> changeMemberStatus(int memberId, String newStatus) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/members/$memberId/status'),
      headers: _getHeaders(token),
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to change status');
    }
  }

  // Dojo Mode APIs
  static Future<Map<String, dynamic>> getDojoModeData(int dojoId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample data
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'settings': {
          'pos_enabled': true,
          'rental_enabled': true,
          'sparring_recording_enabled': true,
          'default_tax_rate': 10.0,
          'default_member_discount': 10.0,
        },
        'today_sales': [
          {
            'id': 1,
            'transaction_type': 'product_sale',
            'total_amount': 5500,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'transaction_type': 'rental',
            'total_amount': 1100,
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
        ],
        'rentals': [
          {
            'id': 1,
            'item_type': 'gi',
            'item_name': '道着（白帯用）',
            'size': 'A2',
            'color': '白',
            'condition': 'good',
            'dojo_id': dojoId,
            'total_quantity': 5,
            'available_quantity': 3,
            'rental_price': 1000,
            'deposit_amount': 5000,
            'status': 'available',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ],
        'products': [
          {
            'id': 1,
            'name': 'プロテイン（ホエイ）',
            'category': 'supplement',
            'current_stock': 15,
            'selling_price': 5000,
            'member_price': 4500,
          },
          {
            'id': 2,
            'name': '道着（A2）',
            'category': 'gi',
            'current_stock': 8,
            'selling_price': 15000,
            'member_price': 13500,
          },
        ],
      };
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/dojo-mode/$dojoId'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dojo mode data');
    }
  }

  static Future<Map<String, dynamic>> processDojoPayment(
    int dojoId,
    List<Map<String, dynamic>> items,
    String paymentMethod,
    int? customerId,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return {
        'transaction_id': DateTime.now().millisecondsSinceEpoch,
        'total_amount': items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']) as int),
        'receipt_url': 'demo_receipt_url',
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/dojo-mode/$dojoId/payment'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'items': items,
        'payment_method': paymentMethod,
        'customer_id': customerId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Payment processing failed');
    }
  }

  static Future<List<Map<String, dynamic>>> getTodaySales(int dojoId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {
          'id': 1,
          'transaction_type': 'product_sale',
          'total_amount': 5500,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/dojo-mode/$dojoId/sales/today'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['sales']);
    } else {
      throw Exception('Failed to load today\'s sales');
    }
  }

  static Future<List<Rental>> getRentals(int dojoId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        Rental(
          id: 1,
          itemType: 'gi',
          itemName: '道着（白帯用）',
          size: 'A2',
          color: '白',
          condition: 'good',
          dojoId: dojoId,
          totalQuantity: 5,
          availableQuantity: 3,
          rentalPrice: 1000,
          depositAmount: 5000,
          status: 'available',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/dojo-mode/$dojoId/rentals'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['rentals'] as List).map((json) => Rental.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load rentals');
    }
  }

  static Future<void> addRentalTransaction(
    int rentalId,
    int userId,
    DateTime returnDueDate,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/rentals/$rentalId/rent'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'user_id': userId,
        'return_due_date': returnDueDate.toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add rental transaction');
    }
  }

  static Future<int> startSparringRecording(
    int dojoId,
    int participant1Id,
    int participant2Id,
    String ruleSet,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return DateTime.now().millisecondsSinceEpoch;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/dojo-mode/$dojoId/sparring/start'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'participant_1_id': participant1Id,
        'participant_2_id': participant2Id,
        'rule_set': ruleSet,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['recording_id'];
    } else {
      throw Exception('Failed to start recording');
    }
  }

  static Future<void> stopSparringRecording(
    int recordingId,
    int? winnerId,
    String finishType,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/sparring-videos/$recordingId/stop'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'winner_id': winnerId,
        'finish_type': finishType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to stop recording');
    }
  }

  // Instructor Management APIs
  static Future<List<InstructorAssignment>> getInstructorAssignments(int instructorId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        InstructorAssignment(
          id: 1,
          instructorId: instructorId,
          dojoId: 1,
          dojoName: 'YAWARA JIU-JITSU ACADEMY',
          usageFee: 50000,
          revenueSharePercentage: 60.0,
          paymentType: 'revenue_share',
          status: 'active',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/instructors/$instructorId/assignments'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['assignments'] as List)
          .map((json) => InstructorAssignment.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load instructor assignments');
    }
  }

  static Future<List<RevenueSummary>> getRevenueSummary(String period) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        RevenueSummary(
          dojoId: 1,
          dojoName: 'YAWARA JIU-JITSU ACADEMY',
          period: DateTime.now(),
          membershipRevenue: 850000,
          productRevenue: 120000,
          rentalRevenue: 35000,
          totalRevenue: 1005000,
          instructorCosts: 350000,
          grossProfit: 655000,
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/revenue?period=$period'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['revenue'] as List)
          .map((json) => RevenueSummary.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load revenue summary');
    }
  }

  // Product Management APIs
  static Future<List<Product>> getProducts({String? category, String? search}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return sample products
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final allProducts = [
        Product(
          id: 1,
          name: 'YAWARA プレミアム道着',
          description: '最高級コットン100%使用の高品質道着。試合規定対応。',
          price: 18000.0,
          category: 'gi',
          imageUrl: 'https://example.com/gi1.jpg',
          stockQuantity: 12,
          isActive: true,
          size: 'A2',
          color: 'white',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 2,
          name: 'ブラック帯 A2サイズ',
          description: 'IBJJF認定黒帯。耐久性に優れた高品質素材使用。',
          price: 8500.0,
          category: 'belt',
          imageUrl: 'https://example.com/belt1.jpg',
          stockQuantity: 8,
          isActive: true,
          size: 'A2',
          color: 'black',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 3,
          name: 'プロ仕様マウスガード',
          description: '成型可能タイプのマウスガード。安全性重視設計。',
          price: 2800.0,
          category: 'protector',
          imageUrl: 'https://example.com/mouthguard1.jpg',
          stockQuantity: 25,
          isActive: true,
          color: 'clear',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 4,
          name: 'JitsuFlow Tシャツ',
          description: '吸湿速乾素材使用のトレーニングTシャツ。',
          price: 3500.0,
          category: 'apparel',
          imageUrl: 'https://example.com/shirt1.jpg',
          stockQuantity: 15,
          isActive: true,
          size: 'L',
          color: 'black',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 5,
          name: 'ラッシュガード 長袖',
          description: 'UVカット機能付き長袖ラッシュガード。',
          price: 5800.0,
          category: 'apparel',
          imageUrl: 'https://example.com/rashguard1.jpg',
          stockQuantity: 20,
          isActive: true,
          size: 'M',
          color: 'navy',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 6,
          name: 'グラップリングダミー',
          description: '自宅練習用グラップリングダミー。70kg相当。',
          price: 28000.0,
          category: 'equipment',
          imageUrl: 'https://example.com/dummy1.jpg',
          stockQuantity: 3,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 7,
          name: '柔術マット 40mm厚',
          description: '高品質EVA素材の柔術専用マット。ジム品質。',
          price: 15000.0,
          category: 'equipment',
          imageUrl: 'https://example.com/mat1.jpg',
          stockQuantity: 7,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 8,
          name: '白帯 A1サイズ',
          description: '初心者向け白帯。IBJJF規定準拠。',
          price: 2500.0,
          category: 'belt',
          imageUrl: 'https://example.com/whitebelt1.jpg',
          stockQuantity: 30,
          isActive: true,
          size: 'A1',
          color: 'white',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 9,
          name: '青帯 A3サイズ',
          description: '青帯ランク用。耐久性と見た目の美しさを両立。',
          price: 4500.0,
          category: 'belt',
          imageUrl: 'https://example.com/bluebelt1.jpg',
          stockQuantity: 18,
          isActive: true,
          size: 'A3',
          color: 'blue',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: 10,
          name: 'プレミアム道着（紺色）',
          description: '試合用紺色道着。IBJJF認定済み。最高品質。',
          price: 22000.0,
          category: 'gi',
          imageUrl: 'https://example.com/bluegiio.jpg',
          stockQuantity: 0, // 在庫切れ
          isActive: true,
          size: 'A3',
          color: 'navy',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Filter by category
      if (category != null && category.isNotEmpty) {
        return allProducts.where((p) => p.category == category).toList();
      }

      // Filter by search
      if (search != null && search.isNotEmpty) {
        return allProducts.where((p) => 
          p.name.toLowerCase().contains(search.toLowerCase()) ||
          p.description.toLowerCase().contains(search.toLowerCase())
        ).toList();
      }

      return allProducts;
    }

    // Build query parameters
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<List<CartItem>> getCart() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode - return empty cart initially
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/cart'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List)
          .map((item) => CartItem(
                product: Product.fromJson(item['product']),
                quantity: item['quantity'],
              ))
          .toList();
    } else {
      throw Exception('Failed to load cart');
    }
  }

  static Future<void> addToCart(int productId, int quantity) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/cart/add'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add to cart');
    }
  }

  static Future<Order> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Demo mode
    if (token.startsWith('demo_token_')) {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final tax = subtotal * 0.1; // 10% tax
      final total = subtotal + tax;

      return Order(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        items: items.map((cartItem) => OrderItem(
          id: cartItem.product.id,
          orderId: DateTime.now().millisecondsSinceEpoch,
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          unitPrice: cartItem.product.price,
          quantity: cartItem.quantity,
          totalPrice: cartItem.totalPrice,
        )).toList(),
        subtotal: subtotal,
        tax: tax,
        total: total,
        status: 'pending',
        shippingAddress: shippingAddress,
        createdAt: DateTime.now(),
      );
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'items': items.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
        }).toList(),
        'shipping_address': shippingAddress,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data['order']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create order');
    }
  }
}