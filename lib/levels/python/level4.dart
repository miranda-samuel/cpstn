import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonLevel4 extends StatefulWidget {
  const PythonLevel4({super.key});

  @override
  State<PythonLevel4> createState() => _PythonLevel4State();
}

class _PythonLevel4State extends State<PythonLevel4> {
  List<String> allBlocks = [];
  List<String> droppedBlocks = [];
  bool gameStarted = false;
  bool isTagalog = false;
  bool isAnsweredCorrectly = false;
  bool level4Completed = false;

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
    // 🔹 Puzzle blocks for Level 4 (example: while loop)
    allBlocks = [
      'while',
      'x',
      '<',
      '5:',
      'print',
      '("x is", x)',
      'x',
      '+=',
      '1',
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
    if (level4Completed) return;
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
    await prefs.setInt('python_level4_score', score);

    if (score > 0) {
      await prefs.setBool('python_level4_completed', true);
    }
  }

  Future<void> loadScoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('python_level4_score');
    final completed = prefs.getBool('python_level4_completed') ?? false;
    setState(() {
      if (savedScore != null) score = savedScore;
      level4Completed = completed;
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
    // 🔹 Correct answer for Level 4
    if (answer == 'while x < 5: print ("x is", x) x += 1') {
      countdownTimer?.cancel();
      isAnsweredCorrectly = true;
      await saveScoreToPrefs(score);
      await sendScoreToBackend(score);

      setState(() {
        level4Completed = true;
      });

      // ✅ Show output in a dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Correct! Level Completed"),
          content: const Text(
            "Output:\nIf x = 0 -> x is 0\nx is 1\nx is 2\nx is 3\nx is 4",
            style: TextStyle(fontFamily: 'monospace'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
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
        title: const Text("🐍 Python - Level 4"),
        backgroundColor: Colors.purple,
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
                Text(" $score",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: level4Completed ? null : startGame,
            icon: const Icon(Icons.play_arrow),
            label: Text(level4Completed ? "Completed" : "Start Game"),
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black),
          ),
          if (level4Completed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "✅ Level 4 already completed!",
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isTagalog = !isTagalog;
                  });
                },
                icon: const Icon(Icons.translate, color: Colors.white),
                label: Text(isTagalog ? 'English' : 'Tagalog',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTagalog
                ? 'Ngayon gusto ni Zeke gumawa ng while loop sa Python! Hangga\'t mas maliit ang x sa 5, i-print ang "x is", x at dagdagan ng 1.'
                : 'Now Zeke wants to use a while loop in Python! While x is less than 5, print "x is", x and increment x by 1.',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
              '🧩 Arrange the puzzle blocks to form: while x < 5: print("x is", x) x += 1',
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 140,
                maxHeight: 400, // maximum height
              ),
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
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
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
          ), //

          const SizedBox(height: 20),
          const Text('📝 Preview:',
              style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.grey[800],
            child: Text(
              getPreviewCode(),
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 18, color: Colors.white),
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
                childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: puzzleBlock(block, Colors.blueAccent)),
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
          if (!level4Completed)
            TextButton(
              onPressed: resetGame,
              child: const Text("🔁 Retry"),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
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
