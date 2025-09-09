import 'dart:async';
import 'package:cpstn/screens/select_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'UserDetailScreen.dart';
import 'login_page.dart';
import 'profile_screen.dart';
import 'level_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF1e3c72);
  static const Color secondaryColor = Color(0xFF2a5298);
  static const Color accentColor = Colors.tealAccent;

  int _userScore = 0;
  List<String> _achievements = [];
  List<_LeaderboardUser> _leaderboardUsers = [];

  final String backendUrl = "http://192.168.100.92/cpstn_backend/api";

  @override
  void initState() {
    super.initState();

    // Initial load
    _refreshData();

    // Auto refresh every 1 second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _refreshData();
      } else {
        timer.cancel();
      }
    });
  }

  // ✅ Load user data from backend
  Future<void> _loadGameData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username ?? 'guest';

    try {
      final response =
      await http.get(Uri.parse('$backendUrl/scores.php?username=$username'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _userScore = data['score'] ?? 0;

          // ✅ Kung wala pang laro, huwag ipakita achievements
          if ((_userScore == 0) &&
              ((data['completedChallenges'] ?? 0) == 0) &&
              ((data['perfectScores'] ?? 0) == 0)) {
            _achievements = [];
          } else {
            _achievements = List<String>.from(data['achievements'] ?? []);
          }
        });
      }
    } catch (e) {
      print("Error loading game data: $e");
    }
  }

  // ✅ Load leaderboard from backend
  Future<void> _loadLeaderboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response =
      await http.get(Uri.parse('$backendUrl/leaderboard.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final currentUsername = authProvider.username;

        List<_LeaderboardUser> leaderboardUsers = data.map((user) {
          return _LeaderboardUser(
            name: user['name'],
            score: user['score'],
            profileImagePath: user['profileImagePath'],
            isCurrentUser: user['name'] == currentUsername,
          );
        }).toList();

        setState(() {
          _leaderboardUsers = leaderboardUsers;
        });
      }
    } catch (e) {
      print("Error loading leaderboard: $e");
    }
  }

  void _refreshData() {
    _loadGameData();
    _loadLeaderboardData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Center(
          child: _CodeSnapLogo(), // 🔹 dito na ang custom logo
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.white, size: 28),
            onPressed: () => _showNotifications(context),
          ),
          _buildProfileMenu(context),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _UserWelcomeCard(score: _userScore, achievements: _achievements),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.code),
                  label: const Text(
                    'Start Coding',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectLanguageScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              _buildLeaderboardSection(context),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'Profile',
            child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profile'))),
        const PopupMenuItem(
            value: 'Settings',
            child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Settings'))),
        const PopupMenuItem(
            value: 'Help',
            child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help & Feedback'))),
        const PopupMenuItem(
            value: 'Logout',
            child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout',
                    style: TextStyle(color: Colors.red)))),
      ],
    );
  }

  Widget _buildLeaderboardSection(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Icon(Icons.leaderboard, color: Colors.amberAccent, size: 28),
                SizedBox(width: 10),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2), // 🔲 Block-style background
                borderRadius: BorderRadius.circular(16),
              ),
              child: _leaderboardUsers.isEmpty
                  ? Center(
                child: Text(
                  'No active users found',
                  style: TextStyle(color: Colors.grey[300], fontSize: 16),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _leaderboardUsers.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildLeaderboardItem(_leaderboardUsers[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(_LeaderboardUser user, int index) {
    return InkWell(
      onTap: () {
        // Navigate to user detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(username: user.name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: user.profileImagePath != null
                  ? ClipOval(
                child: Image.network(
                  user.profileImagePath!,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                ),
              )
                  : ClipOval(
                child: Image.network(
                  'https://ui-avatars.com/api/?name=${user.name.replaceAll(' ', '+')}&background=1e3c72&color=fff',
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: user.isCurrentUser ? Colors.blue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  user.score > 0
                      ? Text(
                    'Completed ${user.score ~/ 20} challenges',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )
                      : Text(
                    'No challenges yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.tealAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${user.score} pts',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _handleMenuSelection(BuildContext context, String value) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    switch (value) {
      case 'Profile':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()))
            .then((_) => _refreshData());
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'Help':
        Navigator.pushNamed(context, '/help');
        break;
      case 'Logout':
        _logout(context);
        break;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.logout();
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_achievements.isEmpty)
              const Text('No new notifications',
                  style: TextStyle(color: Colors.grey))
            else
              ..._achievements.map((achievement) => ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text('New achievement: $achievement'),
                subtitle: const Text('Completed a challenge'),
              )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _UserWelcomeCard extends StatelessWidget {
  final int score;
  final List<String> achievements;

  const _UserWelcomeCard({this.score = 0, this.achievements = const []});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.name ?? 'User';

    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey.withOpacity(0.3)),
              child: authProvider.profileImagePath != null
                  ? ClipOval(
                  child: Image.file(File(authProvider.profileImagePath!),
                      fit: BoxFit.cover, width: 60, height: 60))
                  : const Icon(Icons.person, size: 30, color: Colors.white70),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                score > 0
                    ? Text('$score points',
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 14))
                    : const Text('No points yet',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardUser {
  final String name;
  final int score;
  final String? profileImagePath;
  final bool isCurrentUser;

  _LeaderboardUser(
      {required this.name,
        required this.score,
        this.profileImagePath,
        this.isCurrentUser = false});
}
class _CodeSnapLogo extends StatefulWidget {
  const _CodeSnapLogo();

  @override
  State<_CodeSnapLogo> createState() => _CodeSnapLogoState();
}

class _CodeSnapLogoState extends State<_CodeSnapLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2), // speed ng animation
      vsync: this,
    )..repeat(reverse: true); // back and forth

    _animation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0), // move horizontally
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Code',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(
                  text: 'S',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    fontFamily: 'monospace',
                    shadows: const [
                      Shadow(
                          offset: Offset(1, 2),
                          blurRadius: 3,
                          color: Colors.black26)
                    ],
                  ),
                ),
                TextSpan(
                  text: 'nap',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

