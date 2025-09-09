import 'package:cpstn/levels/python/level3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonLevel2 extends StatefulWidget {
  const PythonLevel2({super.key});

  @override
  State<PythonLevel2> createState() => _PythonLevel2State();
}

class _PythonLevel2State extends State<PythonLevel2> {
  List<String> allBlocks = [];
  List<String> droppedBlocks = [];
  bool gameStarted = false;
  bool isTagalog = false;
  bool isAnsweredCorrectly = false;
  bool level2Completed = false;

  int score = 3;
  int remainingSeconds = 60;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    resetBlocks();
    loadScoreFromPrefs();
  }

  void resetBlocks() {
    allBlocks = [
      'for',
      'i',
      'in',
      'range(5):',
      'print',
      '(i)',
      'printx',
      '("Hi")',
    ]..shuffle();
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      score = 3;
      remainingSeconds = 60;
      droppedBlocks.clear();
      isAnsweredCorrectly = false;
      resetBlocks();
    });
    startTimer();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds == 30 && score > 0) {
          score--;
          saveScoreToPrefs(score);
          sendScoreToBackend(score);
        }
        if (remainingSeconds <= 0) {
          score = 0;
          timer.cancel();
          saveScoreToPrefs(score);
          sendScoreToBackend(score);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("⏰ Time's Up!"),
              content: Text("Score: $score"),
              actions: [
                TextButton(
                  onPressed: () {
                    resetGame();
                    Navigator.pop(context);
                  },
                  child: const Text("Retry"),
                )
              ],
            ),
          );
        }
      });
    });
  }

  void resetGame() {
    if (level2Completed) return;
    setState(() {
      score = 3;
      remainingSeconds = 60;
      gameStarted = false;
      isAnsweredCorrectly = false;
      droppedBlocks.clear();
      countdownTimer?.cancel();
      resetBlocks();
    });
  }

  Future<void> saveScoreToPrefs(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('python_level2_score', score);

    if (score > 0) {
      await prefs.setBool('python_level2_completed', true);
    }
  }

  Future<void> loadScoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('python_level2_score');
    final completed = prefs.getBool('python_level2_completed') ?? false;
    setState(() {
      if (savedScore != null) score = savedScore;
      level2Completed = completed;
    });
  }

  Future<void> sendScoreToBackend(int score) async {
    final username = await getUsername();
    if (username == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.92/cpstn_backend/api/update_score.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'score': score}),
      );

      final data = jsonDecode(response.body);
      if (!(data['status'] ?? false)) {
        print('Failed to update backend score: ${data['message']}');
      }
    } catch (e) {
      print('Error sending score to backend: $e');
    }
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  void checkAnswer() async {
    if (isAnsweredCorrectly || droppedBlocks.isEmpty) return;

    String answer = droppedBlocks.join(' ');
    // 🔹 Correct answer for Level 2
    if (answer == 'for i in range(5): print (i)') {
      countdownTimer?.cancel();
      isAnsweredCorrectly = true;
      await saveScoreToPrefs(score);
      await sendScoreToBackend(score);

      setState(() {
        level2Completed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Correct! Level Completed")),
      );
    } else {
      if (score > 1) {
        setState(() { score--; });
        saveScoreToPrefs(score);
        sendScoreToBackend(score);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Incorrect. -1 point")),
        );
      } else {
        setState(() { score = 0; });
        countdownTimer?.cancel();
        saveScoreToPrefs(score);
        sendScoreToBackend(score);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("💀 Game Over"),
            content: const Text("You lost all your points."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: const Text("Retry"),
              )
            ],
          ),
        );
      }
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String getPreviewCode() {
    return droppedBlocks.join(' ');
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐍 Python - Level 2"),
        backgroundColor: Colors.green,
        actions: gameStarted
            ? [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 4),
                Text(formatTime(remainingSeconds)),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Colors.yellowAccent),
                Text(" $score", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ]
            : [],
      ),
      body: Container(
        color: Colors.black,
        child: gameStarted ? buildGameUI() : buildStartScreen(),
      ),
    );
  }

  Widget buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: level2Completed ? null : startGame,
            icon: const Icon(Icons.play_arrow),
            label: Text(level2Completed ? "Completed" : "Start Game"),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black),
          ),
          if (level2Completed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "✅ Level 2 already completed!",
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildGameUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📖 Short Story',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              TextButton.icon(
                onPressed: () {
                  setState(() { isTagalog = !isTagalog; });
                },
                icon: const Icon(Icons.translate, color: Colors.white),
                label: Text(isTagalog ? 'English' : 'Tagalog', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTagalog
                ? 'Si Zeke ay gusto ngayong gumawa ng loop sa Python! Gusto niyang i-print ang mga numero mula 0 hanggang 4 gamit ang for loop. Pwede mo ba siyang tulungan buuin ang tamang code sa pamamagitan ng pag-aayos ng mga puzzle blocks sa ibaba?'
                : 'Zeke now wants to make a loop in Python! He wants to print numbers from 0 to 4 using a for loop. Can you help him build the correct code by arranging the puzzle blocks below?',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('🧩 Arrange the puzzle blocks to form: for i in range(5): print(i)',
              style: TextStyle(fontSize: 18, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(color: Colors.blueGrey, width: 2.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DragTarget<String>(
              onAccept: (data) {
                if (!isAnsweredCorrectly) {
                  setState(() {
                    droppedBlocks.add(data);
                    allBlocks.remove(data);
                  });
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: droppedBlocks.map((block) {
                      return GestureDetector(
                        onTap: () {
                          if (!isAnsweredCorrectly) {
                            setState(() {
                              droppedBlocks.remove(block);
                              allBlocks.add(block);
                            });
                          }
                        },
                        child: puzzleBlock(block, Colors.greenAccent),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('📝 Preview:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.grey[800],
            child: Text(
              getPreviewCode(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: allBlocks.map((block) {
              return isAnsweredCorrectly
                  ? puzzleBlock(block, Colors.grey)
                  : Draggable<String>(
                data: block,
                feedback: puzzleBlock(block, Colors.blueAccent),
                childWhenDragging: Opacity(opacity: 0.4, child: puzzleBlock(block, Colors.blueAccent)),
                child: puzzleBlock(block, Colors.blueAccent),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: isAnsweredCorrectly ? null : checkAnswer,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Run Code"),
          ),
          if (!level2Completed)
            TextButton(
              onPressed: resetGame,
              child: const Text("🔁 Retry"),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          if (level2Completed)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PythonLevel3(),
                  ),
                );
              },
              icon: const Icon(Icons.navigate_next),
              label: const Text("Next Level"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
        ],
      ),
    );
  }

  Widget puzzleBlock(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.black45, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 16,
        ),
      ),
    );
  }
}
