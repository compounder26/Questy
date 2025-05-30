import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// A service for handling user data persistence
class UserService {
  static const String _userDataKey = 'user_data';
  
  /// Save user data to persistent storage
  static Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userDataKey, userJson);
      print('User data saved successfully. Stars: ${user.starCurrency}');
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }
  
  /// Load user data from persistent storage
  static Future<User?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userDataKey);
      
      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        return User.fromJson(userMap);
      }
      
      return null;
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }
} 