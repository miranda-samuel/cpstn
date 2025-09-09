import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserDetailScreen extends StatefulWidget {
  final String username;

  const UserDetailScreen({required this.username, super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  final String backendUrl = "http://192.168.100.92/cpstn_backend/api";

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final response = await http.get(
          Uri.parse('$backendUrl/user_details.php?username=${widget.username}'));

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user details: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("Failed to load user data"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Score: ${userData!['score'] ?? 0}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            const Text("Challenges Completed:",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            ...List<String>.from(userData!['challenges'] ?? [])
                .map((c) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(c),
            )),
            const SizedBox(height: 12),
            const Text("Badges:",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: List<String>.from(userData!['badges'] ?? [])
                  .map((b) => Chip(label: Text(b)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text("Language Progress:",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            ...Map<String, dynamic>.from(userData!['languages'] ?? {})
                .entries
                .map((e) => ListTile(
              title: Text(e.key),
              trailing: Text("${e.value}%"),
            )),
          ],
        ),
      ),
    );
  }
}
