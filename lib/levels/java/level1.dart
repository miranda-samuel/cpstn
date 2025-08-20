import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// DUMMY LEVEL 2 PAGE
class JavaLevel2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Java - Level 2")),
      body: Center(child: Text("🎉 Welcome to Java Level 2!")),
    );
  }
}

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
      'System.',
      'out.',
      'println',
      '("Hello World");',
      'printx("Hi");',
      'printlnx',
    ]..shuffle();
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      score = 3;
      remainingSeconds = 60;
      droppedBlocks.clear();
      resetBlocks();
    });
    startTimer();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds == 30 && score > 0) {
          score--;
          saveScoreToPrefs(score);
        }
        if (remainingSeconds <= 0) {
          timer.cancel();
          saveScoreToPrefs(score);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("⏰ Time's Up!"),
              content: Text("Score: $score"),
              actions: [
                TextButton(
                  onPressed: () {
                    resetGame();
                    Navigator.pop(context);
                  },
                  child: Text("Retry"),
                )
              ],
            ),
          );
        }
      });
    });
  }

  void resetGame() {
    setState(() {
      score = 3;
      remainingSeconds = 60;
      gameStarted = false;
      droppedBlocks.clear();
      countdownTimer?.cancel();
      resetBlocks();
    });
  }

  Future<void> saveScoreToPrefs(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Java_level1_score', score);
  }

  Future<void> loadScoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('Java_level1_score');
    if (savedScore != null) {
      setState(() {
        score = savedScore;
      });
    }
  }

  void checkAnswer() {
    String answer = droppedBlocks.join('');
    String correct = 'System.out.println("Hello World");';

    if (answer == correct) {
      countdownTimer?.cancel();
      saveScoreToPrefs(score);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("✅ Correct!"),
          content: Text("Well done Totoy! You printed your first Java output!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => JavaLevel2()),
                );
              },
              child: Text("Next Level"),
            )
          ],
        ),
      );
    } else {
      if (score > 0) {
        setState(() {
          score--;
        });
        saveScoreToPrefs(score);
      }

      if (score <= 0) {
        countdownTimer?.cancel();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("💀 Game Over"),
            content: Text("Totoy, you lost all your points."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: Text("Retry"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Incorrect. -1 point")),
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
    return droppedBlocks.join('');
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
        title: Text("☕ Java - Level 1"),
        backgroundColor: Colors.brown,
        actions: gameStarted
            ? [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.timer),
                SizedBox(width: 4),
                Text(formatTime(remainingSeconds)),
                SizedBox(width: 16),
                Icon(Icons.star, color: Colors.yellowAccent),
                Text(" $score", style: TextStyle(fontWeight: FontWeight.bold)),
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
      child: ElevatedButton.icon(
        onPressed: startGame,
        icon: Icon(Icons.play_arrow),
        label: Text("Start Game"),
        style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      ),
    );
  }

  Widget buildGameUI() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📖 Short Story',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isTagalog = !isTagalog;
                  });
                },
                icon: Icon(Icons.translate),
                label: Text(isTagalog ? 'English' : 'Tagalog'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            isTagalog
                ? 'Si Totoy ay unang natututo ng Java! Gusto niyang ipakita ang kanyang unang output gamit ang `System.out.println("Hello World");`. Pwede mo ba siyang tulungan buuin ang tamang code?'
                : 'Totoy is learning Java for the first time! He wants to display his first output using `System.out.println("Hello World");`. Can you help him build the correct code?',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text('🧩 Arrange the puzzle blocks to form: System.out.println("Hello World");',
              style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
          SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.brown, width: 2.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DragTarget<String>(
              onAccept: (data) {
                setState(() {
                  droppedBlocks.add(data);
                  allBlocks.remove(data);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    children: droppedBlocks.map((block) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            droppedBlocks.remove(block);
                            allBlocks.add(block);
                          });
                        },
                        child: codeBlock(block, Colors.greenAccent),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Text('📝 Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.grey[300],
            child: Text(
              getPreviewCode(),
              style: TextStyle(fontFamily: 'monospace', fontSize: 18),
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: allBlocks.map((block) {
              return Draggable<String>(
                data: block,
                feedback: codeBlock(block, Colors.blueAccent),
                childWhenDragging:
                Opacity(opacity: 0.4, child: codeBlock(block, Colors.blueAccent)),
                child: codeBlock(block, Colors.blueAccent),
              );
            }).toList(),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: checkAnswer,
            icon: Icon(Icons.play_arrow),
            label: Text("Run Code"),
          ),
          TextButton(
            onPressed: resetGame,
            child: Text("🔁 Retry"),
          ),
        ],
      ),
    );
  }

  Widget codeBlock(String text, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.black45, width: 1.5),
        boxShadow: [
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
        ),
      ),
    );
  }
}
