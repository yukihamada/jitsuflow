import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class DemoAuth {
  static const String _userKey = 'demo_user';
  static const String _tokenKey = 'demo_token';
  static const String _userTypeKey = 'user_type';
  
  static Future<void> loginAsUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'id': 1,
      'email': 'user@jitsuflow.app',
      'name': 'デモユーザー',
      'phone': null,
      'stripeCustomerId': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_userKey, userData.toString());
    await prefs.setString(_tokenKey, 'demo_token_user_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(_userTypeKey, 'member');
  }
  
  static Future<void> loginAsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'id': 999,
      'email': 'admin@jitsuflow.app',
      'name': '管理者',
      'phone': null,
      'stripeCustomerId': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_userKey, userData.toString());
    await prefs.setString(_tokenKey, 'demo_token_admin_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(_userTypeKey, 'admin');
  }
  
  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'id': 0,
      'email': 'guest@jitsuflow.app',
      'name': 'ゲストユーザー',
      'phone': null,
      'stripeCustomerId': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_userKey, userData.toString());
    await prefs.setString(_tokenKey, 'demo_token_guest_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(_userTypeKey, 'guest');
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
  }
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey) && prefs.containsKey(_tokenKey);
  }
  
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      // Simple parsing - in a real app you'd use proper JSON
      if (userString.contains('管理者')) {
        return '管理者';
      } else if (userString.contains('ゲストユーザー')) {
        return 'ゲストユーザー';
      } else {
        return 'デモユーザー';
      }
    }
    return null;
  }
  
  static Future<String> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey) ?? 'guest';
  }
}