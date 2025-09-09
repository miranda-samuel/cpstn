import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? username;
  String? name;
  String? profileImagePath; // local image path
  String? profileImageUrl;  // network image URL
  int score = 0;

  final SharedPreferences prefs;
  final String backendUrl = "http://192.168.100.92/cpstn_backend/api";

  AuthProvider({required this.prefs});

  void init() {
    username = prefs.getString('username');
    name = prefs.getString('name');
    profileImagePath = prefs.getString('profileImagePath');
    profileImageUrl = prefs.getString('profileImageUrl');
    score = prefs.getInt('score') ?? 0;
    notifyListeners();
  }

  Future<void> login(String usernameInput, String password) async {
    final url = Uri.parse('$backendUrl/login.php');
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameInput,
          "password": password,
        }));

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      username = data['user']['username'];
      name = data['user']['name'];
      profileImagePath = data['user']['profile_image'];
      score = data['user']['score'] ?? 0;

      // Save to SharedPreferences
      await prefs.setString('username', username!);
      await prefs.setString('name', name!);
      if (profileImagePath != null) {
        await prefs.setString('profileImagePath', profileImagePath!);
      }
      await prefs.setInt('score', score);

      notifyListeners();
    } else {
      throw AuthException(data['message']);
    }
  }

  Future<void> signup(String nameInput, String usernameInput, String password) async {
    final url = Uri.parse('$backendUrl/signup.php');
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameInput,
          "username": usernameInput,
          "password": password,
        }));

    final data = jsonDecode(response.body);

    if (data['status'] != true) {
      throw AuthException(data['message']);
    }
  }
  Future<void> setProfileImageUrl(String url) async {
    profileImageUrl = url;
    await prefs.setString('profileImageUrl', url);
    notifyListeners();
  }


  Future<void> logout() async {
    username = null;
    name = null;
    profileImagePath = null;
    score = 0;

    // Clear SharedPreferences
    await prefs.remove('username');
    await prefs.remove('name');
    await prefs.remove('profileImagePath');
    await prefs.remove('score');

    notifyListeners();
  }

  /// Save profile image locally
  Future<void> saveProfileImage(File imageFile) async {
    profileImagePath = imageFile.path;
    profileImageUrl = null; // reset network image
    await prefs.setString('profileImagePath', profileImagePath!);
    notifyListeners();
  }


  /// Change password (dummy backend call)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    // TODO: call backend to change password
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Delete account and logout
  Future<void> deleteAccount([String? password]) async {
    // TODO: call backend to delete account using password
    await logout();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
