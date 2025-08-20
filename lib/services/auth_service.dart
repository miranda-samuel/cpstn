import 'package:flutter/material.dart';

class AuthService {
  // Mock login function - replace with your actual authentication logic
  Future<void> login({
    required String username,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Example validation - replace with real authentication
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required');
    }

    if (username != 'demo' || password != 'password') {
      throw Exception('Invalid credentials');
    }

    // If we get here, login is successful
    debugPrint('Login successful for user: $username');
  }
}