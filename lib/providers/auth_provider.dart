import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AuthProvider with ChangeNotifier, WidgetsBindingObserver {
  final SharedPreferences prefs;
  String? _token;
  String? _username;
  String? _name;
  String? _profileImagePath;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _lastActiveTime;
  bool _shouldLogoutOnResume = false;

  AuthProvider({required this.prefs}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _lastActiveTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        if (_shouldLogoutOnResume) {
          logout();
          _shouldLogoutOnResume = false;
        } else if (_lastActiveTime != null &&
            DateTime.now().difference(_lastActiveTime!).inMinutes >= 30) {
          logout();
        }
        break;
      case AppLifecycleState.detached:
        logout();
        break;
      default:
        break;
    }
  }

  bool get isAuthenticated => _token != null;
  String? get username => _username;
  String? get name => _name;
  String? get profileImagePath => _profileImagePath;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _token = prefs.getString('auth_token');
      _username = prefs.getString('auth_username');
      _name = prefs.getString('auth_name');

      if (_username != null) {
        _profileImagePath = prefs.getString('profile_image_$_username');
      }

      _isInitialized = true;
      _lastActiveTime = DateTime.now();
    } catch (e) {
      await _clearAuthData();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfileImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'profile_${_username}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${directory.path}/$filename');

      _profileImagePath = savedImage.path;
      await prefs.setString('profile_image_$_username', _profileImagePath!);
      notifyListeners();
    } catch (e) {
      throw AuthException('Failed to save profile image: ${e.toString()}');
    }
  }

  Future<void> login(String username, String password) async {
    if (!_isInitialized) await init();

    _isLoading = true;
    notifyListeners();

    try {
      if (username.isEmpty || password.isEmpty) {
        throw AuthException('Username and password are required');
      }

      final users = prefs.getStringList('users') ?? [];
      final user = users.firstWhere(
            (u) => u.startsWith('$username:'),
        orElse: () => '',
      );

      if (user.isEmpty) throw AuthException('User not found');

      final parts = user.split(':');
      if (parts.length < 3) throw AuthException('Invalid user data');

      if (_hashPassword(password) != parts[2]) {
        throw AuthException('Invalid password');
      }

      _token = 'user_token_${DateTime.now().millisecondsSinceEpoch}';
      _username = username;
      _name = parts[1];
      _profileImagePath = prefs.getString('profile_image_$_username');
      _lastActiveTime = DateTime.now();

      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_username', _username!);
      await prefs.setString('auth_name', _name!);

      notifyListeners();
    } catch (e) {
      await _clearAuthData();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String username, String password) async {
    if (!_isInitialized) await init();

    _isLoading = true;
    notifyListeners();

    try {
      if (name.isEmpty || username.isEmpty || password.isEmpty) {
        throw AuthException('All fields are required');
      }
      if (password.length < 4) {
        throw AuthException('Password must be at least 4 characters');
      }
      if (username.contains(':')) {
        throw AuthException('Username cannot contain colons');
      }

      final users = prefs.getStringList('users') ?? [];
      if (users.any((u) => u.startsWith('$username:'))) {
        throw AuthException('Username already exists');
      }

      users.add('$username:$name:${_hashPassword(password)}');
      await prefs.setStringList('users', users);

      _token = 'user_token_${DateTime.now().millisecondsSinceEpoch}';
      _username = username;
      _name = name;
      _profileImagePath = null;
      _lastActiveTime = DateTime.now();

      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_username', _username!);
      await prefs.setString('auth_name', _name!);
      await prefs.remove('profile_image_$_username');

      notifyListeners();
    } catch (e) {
      await _clearAuthData();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String newName, String newUsername) async {
    if (!_isInitialized) await init();

    _isLoading = true;
    notifyListeners();

    try {
      if (newName.isEmpty || newUsername.isEmpty) {
        throw AuthException('Name and username are required');
      }

      if (newUsername.contains(':')) {
        throw AuthException('Username cannot contain colons');
      }

      final users = prefs.getStringList('users') ?? [];
      final userIndex = users.indexWhere((u) => u.startsWith('$_username:'));

      if (userIndex == -1) throw AuthException('User not found');

      if (newUsername != _username && users.any((u) => u.startsWith('$newUsername:'))) {
        throw AuthException('Username already exists');
      }

      final parts = users[userIndex].split(':');
      if (parts.length < 3) throw AuthException('Invalid user data');

      users[userIndex] = '$newUsername:$newName:${parts[2]}';
      await prefs.setStringList('users', users);

      final oldUsername = _username;
      _username = newUsername;
      _name = newName;
      _lastActiveTime = DateTime.now();

      await prefs.setString('auth_username', _username!);
      await prefs.setString('auth_name', _name!);

      if (newUsername != oldUsername && _profileImagePath != null) {
        try {
          final oldFile = File(_profileImagePath!);
          if (await oldFile.exists()) {
            final directory = await getApplicationDocumentsDirectory();
            final filename = 'profile_${_username}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_profileImagePath!)}';
            final newImagePath = '${directory.path}/$filename';

            await oldFile.copy(newImagePath);
            _profileImagePath = newImagePath;
            await prefs.setString('profile_image_$_username', _profileImagePath!);
            await prefs.remove('profile_image_$oldUsername');
          }
        } catch (e) {
          await prefs.setString('profile_image_$_username', _profileImagePath!);
          await prefs.remove('profile_image_$oldUsername');
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (!_isInitialized) await init();

    _isLoading = true;
    notifyListeners();

    try {
      if (oldPassword.isEmpty || newPassword.isEmpty) {
        throw AuthException('Both passwords are required');
      }

      if (newPassword.length < 4) {
        throw AuthException('New password must be at least 4 characters');
      }

      final users = prefs.getStringList('users') ?? [];
      final userIndex = users.indexWhere((u) => u.startsWith('$_username:'));

      if (userIndex == -1) throw AuthException('User not found');

      final parts = users[userIndex].split(':');
      if (parts.length < 3) throw AuthException('Invalid user data');

      if (_hashPassword(oldPassword) != parts[2]) {
        throw AuthException('Current password is incorrect');
      }

      users[userIndex] = '$_username:$_name:${_hashPassword(newPassword)}';
      await prefs.setStringList('users', users);

      _token = 'user_token_${DateTime.now().millisecondsSinceEpoch}';
      _lastActiveTime = DateTime.now();
      await prefs.setString('auth_token', _token!);

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String password) async {
    if (!_isInitialized) await init();

    _isLoading = true;
    notifyListeners();

    try {
      if (password.isEmpty) {
        throw AuthException('Password is required');
      }

      final users = prefs.getStringList('users') ?? [];
      final userIndex = users.indexWhere((u) => u.startsWith('$_username:'));

      if (userIndex == -1) throw AuthException('User not found');

      final parts = users[userIndex].split(':');
      if (parts.length < 3) throw AuthException('Invalid user data');

      if (_hashPassword(password) != parts[2]) {
        throw AuthException('Password is incorrect');
      }

      // Remove the user from the users list
      users.removeAt(userIndex);
      await prefs.setStringList('users', users);

      // Clear all user-specific data
      if (_profileImagePath != null) {
        try {
          final file = File(_profileImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore file deletion errors
        }
      }

      // Clear all user preferences
      await prefs.remove('profile_image_$_username');

      // Clear auth data
      await _clearAuthData();

      // Reset state
      _token = null;
      _username = null;
      _name = null;
      _profileImagePath = null;
      _lastActiveTime = null;

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearAuthData();
    _token = null;
    _username = null;
    _name = null;
    _profileImagePath = null;
    _lastActiveTime = null;
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
    await prefs.remove('auth_name');
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void recordUserActivity() {
    _lastActiveTime = DateTime.now();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}