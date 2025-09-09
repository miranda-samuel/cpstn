import 'package:cpstn/levels/java/level2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class JavaLevel1 extends StatefulWidget {
  const JavaLevel1({super.key});

  @override
  State<JavaLevel1> createState() => _JavaLevel1State();
}

class _JavaLevel1State extends State<JavaLevel1> {
  List<String> allBlocks = [];
  List<String> droppedBlocks = [];
  bool gameStarted = false;
  bool isTagalog = false;
  bool isAnsweredCorrectly = false;
  bool level1Completed = false;

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
      'System.out.print',
      '("Hello World");',
      'System.out.println',
      '("Hi World");',
      'System.out.print("Hello");',
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
          saveScoreToPrefs(score);
        }
        if (remainingSeconds <= 0) {
          score = 0;
          timer.cancel();
          saveScoreToPrefs(score);
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
    if (level1Completed) return;
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
    await prefs.setInt('java_level1_score', score);

    if (score > 0) {
      await prefs.setBool('java_level1_completed', true);
    }
  }

  Future<void> loadScoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('java_level1_score');
    final completed = prefs.getBool('java_level1_completed') ?? false;
    setState(() {
      if (savedScore != null) score = savedScore;
      level1Completed = completed;
    });
  }

  void checkAnswer() async {
    if (isAnsweredCorrectly || droppedBlocks.isEmpty) return;

    String answer = droppedBlocks.join(' ');
    if (answer == 'System.out.print ("Hello World");') {
      countdownTimer?.cancel();
      isAnsweredCorrectly = true;
      await saveScoreToPrefs(score);

      setState(() {
        level1Completed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Correct! Level Completed")),
      );
    } else {
      if (score > 1) {
        setState(() {
          score--;
        });
        saveScoreToPrefs(score);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Incorrect. -1 point")),
        );
      } else {
        setState(() {
          score = 0;
        });
        countdownTimer?.cancel();
        saveScoreToPrefs(score);
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
        title: const Text("☕ Java - Level 1"),
        backgroundColor: Colors.red,
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
      body: gameStarted ? buildGameUI() : buildStartScreen(),
    );
  }

  Widget buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: level1Completed ? null : startGame,
            icon: const Icon(Icons.play_arrow),
            label: Text(level1Completed ? "Completed" : "Start Game"),
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
          if (level1Completed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "✅ Level 1 already completed!",
                style: TextStyle(color: Colors.green),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isTagalog = !isTagalog;
                  });
                },
                icon: const Icon(Icons.translate),
                label: Text(isTagalog ? 'English' : 'Tagalog'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isTagalog
                ? 'Si Zeke ay natututo ng Java! Gusto niyang ipakita ang kanyang unang output gamit ang System.out.print("Hello World");. Pwede mo ba siyang tulungan buuin ang tamang code?'
                : 'Zeke is learning Java for the first time! He wants to display his first output using System.out.print("Hello World");. Can you help him build the correct code?',
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text('🧩 Arrange the puzzle blocks to form: System.out.print("Hello World");',
              style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
          const Text('📝 Preview:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.grey[300],
            child: Text(
              getPreviewCode(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
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
          if (!level1Completed)
            TextButton(
              onPressed: resetGame,
              child: const Text("🔁 Retry"),
            ),
          if (level1Completed) // 🔑 kapag completed na, lalabas yung Next Level button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JavaLevel2(),
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
