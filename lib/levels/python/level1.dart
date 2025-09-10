import 'package:cpstn/levels/python/level2.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonLevel1 extends StatefulWidget {
  const PythonLevel1({super.key});

  @override
  State<PythonLevel1> createState() => _PythonLevel1State();
}

class _PythonLevel1State extends State<PythonLevel1>
    with SingleTickerProviderStateMixin {
  List<String> allBlocks = [];
  List<String> droppedBlocks = [];
  bool gameStarted = false;
  bool isTagalog = false;
  bool isAnsweredCorrectly = false;
  bool level1Completed = false;

  int score = 3;
  int remainingSeconds = 60;
  Timer? countdownTimer;

  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    resetBlocks();

    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _colorAnimation = _controller.drive(
      ColorTween(begin: Colors.greenAccent, end: Colors.blueAccent),
    );
    _controller.repeat(reverse: true);

    // Optional: Load level completion and score from backend here
    // fetchScoreFromBackend();
  }

  void resetBlocks() {
    allBlocks = [
      'print',
      '("Hello World")',
      'printx',
      '("Hi World")',
      'print("Hello")',
      ';',
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
          sendScoreToBackend(score);
        }
        if (remainingSeconds <= 0) {
          score = 0;
          timer.cancel();
          sendScoreToBackend(score);
          showFancyDialog(context, "⏰ Time's Up!", "Score: $score",
              isGameOver: true);
        }
      });
    });
  }

  void resetGame() {
    setState(() {
      score = 3;
      remainingSeconds = 60;
      gameStarted = false;
      isAnsweredCorrectly = false;
      level1Completed = false;
      droppedBlocks.clear();
      countdownTimer?.cancel();
      resetBlocks();
    });
  }

  Future<void> sendScoreToBackend(int score) async {
    final username = await getUsername();
    if (username == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.100.92/cpstn_backend/api/update_score.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'score': score}),
      );

      final data = jsonDecode(response.body);
      if (data['status'] ?? false) {
        setState(() {
          level1Completed = true;
          this.score = score;
        });
      } else {
        print('Failed to update backend score: ${data['message']}');
      }
    } catch (e) {
      print('Error sending score to backend: $e');
    }
  }

  Future<String?> getUsername() async {
    // Replace this with your backend or provider logic if needed
    // Currently returning a dummy username
    return 'demoUser';
  }

  void checkAnswer() async {
    if (isAnsweredCorrectly || droppedBlocks.isEmpty) return;

    String answer = droppedBlocks.join(' ');
    if (answer == 'print ("Hello World") ;') {
      countdownTimer?.cancel();
      isAnsweredCorrectly = true;
      await sendScoreToBackend(score);

      setState(() {
        level1Completed = true;
      });

      showFancyDialog(
          context, "✅ Correct! Level Completed", "Output:\nHello World");
    } else {
      if (score > 1) {
        setState(() {
          score--;
        });
        sendScoreToBackend(score);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Incorrect. -1 point")),
        );
      } else {
        setState(() {
          score = 0;
        });
        countdownTimer?.cancel();
        sendScoreToBackend(score);
        showFancyDialog(
            context, "💀 Game Over", "You lost all your points.",
            isGameOver: true);
      }
    }
  }

  void showFancyDialog(BuildContext context, String title, String message,
      {bool isGameOver = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isGameOver
                        ? [Colors.red, Colors.orange]
                        : [Colors.green, Colors.teal, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (isGameOver) resetGame();
                        },
                        child: const Text("OK"),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐍 Python - Level 1"),
        backgroundColor: Colors.green,
        actions: gameStarted
            ? [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  formatTime(remainingSeconds),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Colors.yellowAccent),
                Text(
                  " $score",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
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
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            child: ElevatedButton.icon(
              onPressed: startGame,
              icon: const Icon(Icons.play_arrow),
              label: Text(level1Completed ? "Retry Level" : "Start Game"),
              style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black),
            ),
          ),
          if (level1Completed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  const Text(
                    "✅ Level 1 already completed!",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "⭐ Score: $score / 3",
                    style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
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
                ? 'Si Zeke ay unang natututo ng Python! Gusto niyang ipakita ang kanyang unang output gamit ang print("Hello World"). Pwede mo ba siyang tulungan buuin ang tamang code sa pamamagitan ng pag-aayos ng mga puzzle blocks sa ibaba?'
                : 'Zeke is learning Python for the first time! He wants to display his first output using print("Hello World"). Can you help him build the correct code by arranging the puzzle blocks below?',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
              '🧩 Arrange the puzzle blocks to form: print("Hello World");',
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center),
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
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: 1.0,
                        child: GestureDetector(
                          onTap: () {
                            if (!isAnsweredCorrectly) {
                              setState(() {
                                droppedBlocks.remove(block);
                                allBlocks.add(block);
                              });
                            }
                          },
                          child: puzzleBlock(block, Colors.greenAccent),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('📝 Preview:',
              style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
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
                feedback: AnimatedScale(
                    scale: 1.1,
                    duration: const Duration(milliseconds: 200),
                    child: puzzleBlock(block, Colors.blueAccent)),
                childWhenDragging: Opacity(
                    opacity: 0.4, child: puzzleBlock(block, Colors.blueAccent)),
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
          if (level1Completed)
            TextButton.icon(
              onPressed: resetGame,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("🔁 Retry Level"),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          if (level1Completed)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PythonLevel2(),
                  ),
                );
              },
              icon: const Icon(Icons.navigate_next),
              label: const Text("Next Level"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
            ),
        ],
      ),
    );
  }

  Widget puzzleBlock(String text, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 16,
          color: Colors.primaries[
          text.hashCode % Colors.primaries.length], // colorful text
        ),
      ),
    );
  }
}
