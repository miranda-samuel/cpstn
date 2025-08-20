import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'profile_screen.dart';
import 'game_screen.dart';

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
  int _completedChallenges = 0;
  List<String> _achievements = [];
  List<_LeaderboardUser> _leaderboardUsers = [];

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _loadLeaderboardData();
  }

  Future<void> _loadGameData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final languages = ['python', 'java', 'c++', 'php', 'sql'];
    final username = authProvider.username ?? 'guest';

    int totalScore = 0;
    int completedChallenges = 0;
    List<String> achievements = [];

    for (var language in languages) {
      for (int level = 1; level <= 5; level++) {
        final key = '${username}_${language}_level${level}_score';
        final score = prefs.getInt(key) ?? 0;
        if (score > 0) {
          completedChallenges++;
          totalScore += score * 10;
        }
      }
    }

    if (completedChallenges >= 1) achievements.add('Beginner Coder');
    if (completedChallenges >= 5) achievements.add('Code Explorer');
    if (completedChallenges >= 10) achievements.add('Master Programmer');

    int perfectScores = 0;
    for (var language in languages) {
      for (int level = 1; level <= 5; level++) {
        final key = '${username}_${language}_level${level}_score';
        if (prefs.getInt(key) == 3) perfectScores++;
      }
    }
    if (perfectScores >= 3) achievements.add('Perfectionist');
    if (perfectScores >= 1) achievements.add('Three Star Coder');

    setState(() {
      _userScore = totalScore;
      _completedChallenges = completedChallenges;
      _achievements = achievements;
    });
  }

  Future<void> _loadLeaderboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final languages = ['python', 'java', 'c++', 'php', 'sql'];

    try {
      final users = prefs.getStringList('users') ?? [];
      final leaderboardUsers = <_LeaderboardUser>[];

      // Calculate current user score first
      final currentUsername = authProvider.username;
      if (currentUsername != null) {
        int currentUserScore = 0;
        for (var language in languages) {
          for (int level = 1; level <= 5; level++) {
            final key = '${currentUsername}_${language}_level${level}_score';
            currentUserScore += (prefs.getInt(key) ?? 0) * 10;
          }
        }

        // Only add current user if they have at least one score
        if (currentUserScore > 0) {
          leaderboardUsers.add(
            _LeaderboardUser(
              name: authProvider.name ?? currentUsername,
              score: currentUserScore,
              profileImagePath: authProvider.profileImagePath,
              isCurrentUser: true,
            ),
          );
        }
      }

      // Calculate other users' scores
      for (var userString in users) {
        final parts = userString.split(':');
        final username = parts[0];
        if (username == authProvider.username) continue;

        int userScore = 0;
        for (var language in languages) {
          for (int level = 1; level <= 5; level++) {
            final key = '${username}_${language}_level${level}_score';
            userScore += (prefs.getInt(key) ?? 0) * 10;
          }
        }

        // Only add user if they have at least one score
        if (userScore > 0) {
          leaderboardUsers.add(
            _LeaderboardUser(
              name: parts.length > 1 ? parts[1] : username,
              score: userScore,
              profileImagePath: prefs.getString('profile_image_$username'),
              isCurrentUser: false,
            ),
          );
        }
      }

      // Sort by score descending
      leaderboardUsers.sort((a, b) => b.score.compareTo(a.score));

      setState(() {
        _leaderboardUsers = leaderboardUsers;
      });
    } catch (e) {
      // If current user has score but error occurs, still show them
      if (authProvider.username != null && _userScore > 0) {
        setState(() {
          _leaderboardUsers = [
            _LeaderboardUser(
              name: authProvider.name ?? 'You',
              score: _userScore,
              profileImagePath: authProvider.profileImagePath,
              isCurrentUser: true,
            )
          ];
        });
      }
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
        title: const Text('CodeSnap',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
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
              const SizedBox(height: 30),
              _buildMainActionButton(context),
              const SizedBox(height: 40),
              _buildLeaderboardSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickStartMenu(context),
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
            title: Text('Profile'),
          ),
        ),
        const PopupMenuItem(
          value: 'Settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuItem(
          value: 'Help',
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help & Feedback'),
          ),
        ),
        const PopupMenuItem(
          value: 'Logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow, size: 26),
      label: const Text('Start Coding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      onPressed: () => Navigator.pushNamed(context, '/select_language').then((_) => _refreshData()),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
        shadowColor: accentColor.withOpacity(0.4),
      ),
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
                Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5))],
              ),
              child: _leaderboardUsers.isEmpty
                  ? Center(child: Text('No active users found', style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                  : ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: RefreshIndicator(
                  onRefresh: _loadLeaderboardData,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: _leaderboardUsers.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300], indent: 80),
                    itemBuilder: (context, index) => _buildLeaderboardItem(_leaderboardUsers[index], index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(_LeaderboardUser user, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey[200],
        child: user.profileImagePath != null
            ? ClipOval(child: Image.file(File(user.profileImagePath!), fit: BoxFit.cover, width: 52, height: 52))
            : ClipOval(
          child: Image.network(
            'https://ui-avatars.com/api/?name=${user.name.replaceAll(' ', '+')}&background=1e3c72&color=fff',
            fit: BoxFit.cover,
            width: 52,
            height: 52,
          ),
        ),
      ),
      title: Text(user.name, style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: user.isCurrentUser ? Colors.blue : Colors.black,
      )),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${user.score} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      subtitle: Text('Completed ${user.score ~/ 20} challenges', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Profile':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
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
        SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_achievements.isEmpty)
              const Text('No new notifications', style: TextStyle(color: Colors.grey))
            else
              ..._achievements.map((achievement) => ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text('New achievement: $achievement'),
                subtitle: const Text('Completed a challenge'),
              )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQuickStartMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quick Start', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.teal),
              title: const Text('Continue Last Challenge'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined, color: Colors.blue),
              title: const Text('Select Language'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/select_language').then((_) => _refreshData());
              },
            ),
            const SizedBox(height: 10),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
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
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
              ),
              child: authProvider.profileImagePath != null
                  ? ClipOval(
                child: Image.file(
                  File(authProvider.profileImagePath!),
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                ),
              )
                  : const Icon(Icons.person, size: 30, color: Colors.white70),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$score points', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.stars_rounded, color: Colors.amber),
              onPressed: () => _showAchievements(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievements(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Achievements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (achievements.isEmpty)
              const Column(
                children: [
                  Icon(Icons.emoji_events, size: 60, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Complete challenges to unlock achievements'),
                ],
              )
            else
              Column(
                children: [
                  const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                  const SizedBox(height: 10),
                  ...achievements.map((achievement) => ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(achievement),
                  )).toList(),
                ],
              ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: achievements.length / 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Colors.teal),
            ),
            const SizedBox(height: 10),
            Text('${achievements.length} of 6 achievements unlocked'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardUser {
  final String name;
  final int score;
  final String? profileImagePath;
  final bool isCurrentUser;

  _LeaderboardUser({
    required this.name,
    required this.score,
    this.profileImagePath,
    required this.isCurrentUser,
  });
}