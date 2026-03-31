import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class LocalStorageService {
  static const String userKey = "USER_DATA";

  // Save user
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(user.toMap());
    await prefs.setString(userKey, jsonString);
  }

  // Get user
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(userKey);

    if (jsonString == null) return null;

    final Map<String, dynamic> map = jsonDecode(jsonString);
    return UserModel.fromMap(map);
  }

  // Clear user
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }
}
