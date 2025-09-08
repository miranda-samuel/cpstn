import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 👉 import mo yung level file (Python Level 1)
import 'package:cpstn/levels/python/level1.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late String selectedLanguage;
  Map<String, int> scores = {};
  bool isLoading = true;
  final int totalLevels = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    selectedLanguage = args is String ? args : 'Python';
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final loadedScores = <String, int>{};

    for (int i = 1; i <= totalLevels; i++) {
      final scoreKey = '${selectedLanguage.toLowerCase()}_level${i}_score';
      final completedKey =
          '${selectedLanguage.toLowerCase()}_level${i}_completed';

      loadedScores[scoreKey] = prefs.getInt(scoreKey) ?? 0;
      loadedScores[completedKey] = prefs.getBool(completedKey) == true ? 1 : 0;
    }

    if (mounted) {
      setState(() {
        scores = loadedScores;
        isLoading = false;
      });
    }
  }

  bool _isLevelUnlocked(int levelIndex) {
    if (levelIndex == 1) return true;

    final prevCompletedKey =
        '${selectedLanguage.toLowerCase()}_level${levelIndex - 1}_completed';

    // ✅ unlock if previous level was marked as completed
    return scores[prevCompletedKey] == 1;
  }

  String _getLevelRoute(int levelIndex) {
    return '/game/${selectedLanguage.toLowerCase()}/$levelIndex';
  }

  Widget _buildLevelCard(int levelIndex) {
    final isUnlocked = _isLevelUnlocked(levelIndex);
    final scoreKey =
        '${selectedLanguage.toLowerCase()}_level${levelIndex}_score';
    final completedKey =
        '${selectedLanguage.toLowerCase()}_level${levelIndex}_completed';

    final score = scores[scoreKey] ?? 0;
    final completed = scores[completedKey] == 1;

    final stars = List.generate(
      3,
          (starIndex) => Icon(
        starIndex < score ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.9),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isUnlocked
              ? () {
            // 👉 special case: Python Level 1
            if (selectedLanguage.toLowerCase() == "python" &&
                levelIndex == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PythonLevel1()),
              ).then((_) => _loadScores()); // refresh after return
            } else {
              // 👉 fallback sa generic route
              Navigator.pushNamed(
                context,
                _getLevelRoute(levelIndex),
              ).then((_) => _loadScores()); // refresh after return
            }
          }
              : () => _showLockedDialog(context, levelIndex),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.teal.shade100
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked ? Icons.code : Icons.lock,
                    color: isUnlocked
                        ? Colors.teal.shade700
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $levelIndex',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(children: stars),
                      if (completed)
                        const Text(
                          "✅ Completed",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isUnlocked ? Colors.teal.shade700 : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, int levelIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🔒 Level Locked"),
        content: Text(
          "Complete Level ${levelIndex - 1} to unlock this level.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('$selectedLanguage Levels'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: totalLevels,
                  itemBuilder: (context, index) {
                    return _buildLevelCard(index + 1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
