import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


class GameScreen extends StatefulWidget {
  final String language;
  final int level;
  final String username;
  final VoidCallback? onScoreUpdated;

  const GameScreen({
    super.key,
    required this.language,
    required this.level,
    required this.username,
    this.onScoreUpdated,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<String> codeBlocks;
  late String correctAnswer;
  late String challengeDescription;
  List<String> droppedBlocks = [];
  bool isCompleted = false;
  bool isDragging = false;
  int attempts = 0;
  int score = 0;
  bool showSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    _setupChallenge();
    _loadProgress();
  }

  void _setupChallenge() {
    switch ('${widget.language} - Level ${widget.level}') {
      case 'Python - Level 1':
        codeBlocks = ['print', '(', '"Hello World"', ')'];
        correctAnswer = 'print("Hello World")';
        challengeDescription = 'Arrange the blocks to print "Hello World"';
        break;
      case 'Python - Level 2':
        codeBlocks = ['def', 'hello', '(', ')', ':', 'print', '(', '"Hi"', ')'];
        correctAnswer = 'def hello(): print("Hi")';
        challengeDescription = 'Create a function that prints "Hi"';
        break;
      case 'Java - Level 1':
        codeBlocks = ['System.out.println', '(', '"Java"', ')', ';'];
        correctAnswer = 'System.out.println("Java");';
        challengeDescription = 'Print "Java" to the console';
        break;
      case 'C++ - Level 1':
        codeBlocks = ['cout', '<<', '"C++"', '<<', 'endl', ';'];
        correctAnswer = 'cout << "C++" << endl;';
        challengeDescription = 'Print "C++" using cout';
        break;
      case 'PHP - Level 1':
        codeBlocks = ['echo', '"PHP"', ';'];
        correctAnswer = 'echo "PHP";';
        challengeDescription = 'Print "PHP" using echo';
        break;
      default:
        codeBlocks = ['print', '(', '"Default"', ')'];
        correctAnswer = 'print("Default")';
        challengeDescription = 'Complete the code challenge';
    }

    codeBlocks.shuffle();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${widget.username}_${widget.language.toLowerCase()}_level${widget.level}_score';
    setState(() {
      score = prefs.getInt(key) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${widget.username}_${widget.language.toLowerCase()}_level${widget.level}_score';

    // Calculate new score (3 stars for 1 attempt, 2 for 2, 1 for 3+)
    final newScore = (3 - (attempts - 1).clamp(0, 2)).clamp(1, 3);

    if (newScore > score) {
      await prefs.setInt(key, newScore);
      await _updateTotalScore(newScore, score);
      await _updateLeaderboard(newScore);
      setState(() => score = newScore);

      // Notify parent about score update
      if (widget.onScoreUpdated != null) {
        widget.onScoreUpdated!();
      }
    }

    if (!showSuccessDialog) {
      showSuccessDialog = true;
      _showSuccessDialog(newScore);
    }
  }

  Future<void> _updateTotalScore(int newScore, int oldScore) async {
    final prefs = await SharedPreferences.getInstance();
    final totalScoreKey = '${widget.username}_total_score';
    final currentTotal = prefs.getInt(totalScoreKey) ?? 0;

    // Calculate points to add (10 per star)
    int pointsToAdd = newScore * 10;

    // Subtract previous score if it existed
    if (oldScore > 0) {
      pointsToAdd -= oldScore * 10;
    }

    await prefs.setInt(totalScoreKey, currentTotal + pointsToAdd);
  }

  Future<void> _updateLeaderboard(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    final leaderboardKey = 'leaderboard_${widget.language.toLowerCase()}_level${widget.level}';
    final leaderboardData = prefs.getStringList(leaderboardKey) ?? [];

    // Remove old entry if exists
    leaderboardData.removeWhere((entry) => entry.startsWith('${widget.username}:'));

    // Add new entry with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    leaderboardData.add('${widget.username}:$newScore:$timestamp');

    await prefs.setStringList(leaderboardKey, leaderboardData);
  }

  void checkAnswer() {
    final answer = droppedBlocks.join('').replaceAll(' ', '');
    attempts++;

    if (answer == correctAnswer.replaceAll(' ', '')) {
      _saveProgress();
    } else {
      _showErrorFeedback();
    }
  }

  void _showSuccessDialog(int newScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("✅ Correct!", style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You completed Level ${widget.level} in ${widget.language}!",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star,
                  color: index < newScore ? Colors.amber : Colors.grey[300],
                  size: 50,
                );
              }),
            ),
            if (attempts > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Completed in $attempts attempts",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              "Earned ${newScore * 10} points!",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    ).then((_) {
      showSuccessDialog = false;
    });
  }

  void _showErrorFeedback() {
    Feedback.forTap(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("❌ Try again!", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'HINT',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("💡 Hint"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Try to recreate:"),
                    const SizedBox(height: 10),
                    Text(
                      correctAnswer,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Got it"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.language} - Level ${widget.level}'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("📖 Challenge Info"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challengeDescription),
                      const SizedBox(height: 20),
                      const Text("Example Solution:"),
                      const SizedBox(height: 10),
                      Text(
                        correctAnswer,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFECE9E6), Color(0xFFFFFFFF)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Challenge:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      challengeDescription,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Your score: "),
                          ...List.generate(3, (index) {
                            return Icon(
                              Icons.star,
                              color: index < score ? Colors.amber : Colors.grey[300],
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 10),
                          Text(
                            "${score * 10} points",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDragging
                          ? Colors.teal.withOpacity(0.5)
                          : droppedBlocks.isEmpty
                          ? Colors.grey
                          : Colors.teal,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: droppedBlocks.isEmpty
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Drag code blocks here',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    )
                        : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: droppedBlocks.map((block) {
                        return Draggable<String>(
                          data: block,
                          feedback: _codeBlock(block, isDragging: true),
                          child: _codeBlock(block),
                          onDragStarted: () => setState(() => isDragging = true),
                          onDragEnd: (_) => setState(() => isDragging = false),
                          onDraggableCanceled: (_, __) {
                            setState(() {
                              isDragging = false;
                              droppedBlocks.remove(block);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              onWillAccept: (data) => true,
              onAccept: (data) {
                setState(() {
                  droppedBlocks.add(data);
                  isDragging = false;
                });
              },
              onLeave: (_) => setState(() => isDragging = false),
            ),
            const SizedBox(height: 30),
            const Text(
              'Available Blocks:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: codeBlocks.map((block) {
                return Draggable<String>(
                  data: block,
                  feedback: _codeBlock(block, isDragging: true),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _codeBlock(block),
                  ),
                  child: droppedBlocks.contains(block)
                      ? const SizedBox.shrink()
                      : _codeBlock(block),
                  onDragStarted: () => setState(() => isDragging = true),
                  onDragEnd: (_) => setState(() => isDragging = false),
                  onDraggableCanceled: (_, __) => setState(() => isDragging = false),
                );
              }).toList(),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: droppedBlocks.isEmpty ? null : checkAnswer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: droppedBlocks.isEmpty
                      ? null
                      : () {
                    setState(() {
                      droppedBlocks.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeBlock(String text, {bool isDragging = false}) {
    return Material(
      elevation: isDragging ? 8 : 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDragging ? Colors.teal[100] : _getBlockColor(text),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDragging ? Colors.teal : _getBlockBorderColor(text),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _getTextColor(text),
          ),
        ),
      ),
    );
  }

  Color _getBlockColor(String text) {
    if (text.contains('"')) return Colors.lightGreen[100]!;
    if (text == '(' || text == ')') return Colors.blueGrey[100]!;
    if (text == ';' || text == ':') return Colors.purple[100]!;
    if (text.contains('.')) return Colors.orange[100]!;
    return Colors.blue[100]!;
  }

  Color _getBlockBorderColor(String text) {
    if (text.contains('"')) return Colors.lightGreen[300]!;
    if (text == '(' || text == ')') return Colors.blueGrey[300]!;
    if (text == ';' || text == ':') return Colors.purple[300]!;
    if (text.contains('.')) return Colors.orange[300]!;
    return Colors.blue[300]!;
  }

  Color _getTextColor(String text) {
    if (text.contains('"')) return Colors.green[800]!;
    if (text == '(' || text == ')') return Colors.blueGrey[800]!;
    if (text == ';' || text == ':') return Colors.purple[800]!;
    if (text.contains('.')) return Colors.orange[800]!;
    return Colors.blue[800]!;
  }
}

class _LeaderboardEntry {
  final String username;
  final int score;
  final int timestamp;

  _LeaderboardEntry({
    required this.username,
    required this.score,
    required this.timestamp,
  });
}