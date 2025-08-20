import 'package:flutter/material.dart';
import "package:shared_preferences/shared_preferences.dart";
import 'dart:async';
import 'dart:math';

class PythonLevel2 extends StatefulWidget {
  const PythonLevel2({super.key});

  @override
  State<PythonLevel2> createState() => _PythonLevel2State();
}

class _PythonLevel2State extends State<PythonLevel2> {
  final List<String> correctSequence = ['x', '=', '5', 'print', '(', 'x', ')'];

  late List<Map<String, dynamic>> initialBlocks;
  late List<Map<String, dynamic>> codeBlocks;
  List<Map<String, dynamic>?> droppedBlocks = List.filled(7, null);

  bool isTagalog = false;
  bool gameStarted = false;
  int score = 3;
  Timer? countdownTimer;
  int remainingSeconds = 120;

  @override
  void initState() {
    super.initState();
    initialBlocks = List.generate(correctSequence.length, (i) {
      return {'text': correctSequence[i], 'id': i};
    });
    codeBlocks = List.from(initialBlocks)..shuffle(Random());
    loadScoreFromPrefs();
  }

  Future<void> saveScoreToPrefs(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('python_level2_score', score);
  }

  Future<void> loadScoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('python_level2_score');
    if (savedScore != null) {
      setState(() {
        score = savedScore;
      });
    }
  }

  void startGame() {
    setState(() {
      gameStarted = true;
    });
    startTimer();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds == 60 && score > 0) {
          score--;
          saveScoreToPrefs(score);
        }
        if (remainingSeconds <= 0) {
          timer.cancel();
          showResultDialog("⏱ Time's Up", "Your score: $score");
        }
        if (score <= 0) {
          timer.cancel();
          showResultDialog("💀 Game Over", "You lost all your points.");
        }
      });
    });
  }

  void checkAnswer() async {
    final answer = droppedBlocks.map((e) => e?['text'] ?? '').join(' ');
    final prefs = await SharedPreferences.getInstance();

    if (answer == correctSequence.join(' ')) {
      // ✅ Mark score as 3 (perfect) no matter what
      score = 3;
      await prefs.setInt('python_level2_score', score);

      countdownTimer?.cancel();
      showResultDialog("🎉 Well Done!", "You completed Level 2!\nScore: $score", nextLevel: true);
    } else {
      if (score > 0) {
        setState(() {
          score--;
        });
        await prefs.setInt('python_level2_score', score);
      }
      if (score <= 0) {
        countdownTimer?.cancel();
        showResultDialog("💀 Game Over", "You lost all your points.");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Incorrect. -1 point")),
        );
      }
    }
  }


  void showResultDialog(String title, String message, {bool nextLevel = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (nextLevel)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/python_level3');
              },
              child: Text("Next Level"),
            ),
          TextButton(
            onPressed: () {
              saveScoreToPrefs(3);
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PythonLevel2()));
            },
            child: Text("Retry"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🐍 Python - Level 2"),
        backgroundColor: Colors.teal,
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
        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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
              Text('📚 Short Story', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          SizedBox(height: 6),
          Text(
            isTagalog
                ? 'Kilalanin si Zeke, ang batang programmer! Gusto niyang ilagay ang numerong 5 sa isang variable na x at i-print ito para magamit sa kanyang game score...'
                : 'Meet Zeke, the young coder! Today, Zeke wants to assign the number 5 to a variable named x and print it out...',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isTagalog
                  ? '🧩 Ipagdugtong ang mga code block para mabuo: x = 5 at i-print ang x'
                  : '🧩 Match the puzzle blocks to build: x = 5 then print x',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(correctSequence.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DragTarget<Map<String, dynamic>>(
                      onAccept: (data) {
                        setState(() {
                          final existing = droppedBlocks[index];
                          if (existing != null) {
                            codeBlocks.add(existing);
                          }
                          droppedBlocks[index] = data;
                          codeBlocks.remove(data);
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        final block = droppedBlocks[index];
                        final text = block?['text'];
                        final shapeId = block?['id'] ?? index;
                        return GestureDetector(
                          onTap: () {
                            if (block != null) {
                              setState(() {
                                codeBlocks.add(block);
                                droppedBlocks[index] = null;
                              });
                            }
                          },
                          child: ClipPath(
                            key: ValueKey('drop-$index-${block?['id'] ?? 'empty'}'),
                            clipper: PuzzleClipper(shapeId),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: text != null ? Colors.greenAccent : Colors.grey[300],
                              alignment: Alignment.center,
                              child: Text(
                                text ?? '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('📄 Preview:'),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 60),
            padding: EdgeInsets.all(10),
            color: Colors.grey[300],
            child: Text(
              droppedBlocks.where((e) => e != null).map((e) => e!['text']).join(' ') +
                  (droppedBlocks.every((e) => e != null) ? ' ;' : ''),
              style: TextStyle(fontSize: 18, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: codeBlocks.map((block) {
                return Draggable<Map<String, dynamic>>(
                  data: block,
                  feedback: puzzleBlock(block['text'], Colors.blueAccent, block['id'],
                      key: ValueKey('drag-feedback-${block['id']}')),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: puzzleBlock(block['text'], Colors.blueAccent, block['id'],
                        key: ValueKey('drag-dimmed-${block['id']}')),
                  ),
                  child: puzzleBlock(block['text'], Colors.blueAccent, block['id'],
                      key: ValueKey('drag-${block['id']}')),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: checkAnswer,
              icon: Icon(Icons.play_arrow),
              label: Text("Run Code"),
            ),
          ),
        ],
      ),
    );
  }

  Widget puzzleBlock(String text, Color color, int shapeIndex, {Key? key}) {
    return ClipPath(
      key: key,
      clipper: PuzzleClipper(shapeIndex),
      child: Container(
        width: 60,
        height: 60,
        color: color,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class PuzzleClipper extends CustomClipper<Path> {
  final int type;
  PuzzleClipper(this.type);

  @override
  Path getClip(Size size) {
    final path = Path();
    switch (type % 3) {
      case 0:
        path.moveTo(0, size.height * 0.2);
        path.lineTo(size.width * 0.3, 0);
        path.lineTo(size.width * 0.7, 0);
        path.lineTo(size.width, size.height * 0.2);
        path.lineTo(size.width, size.height * 0.8);
        path.lineTo(size.width * 0.7, size.height);
        path.lineTo(size.width * 0.3, size.height);
        path.lineTo(0, size.height * 0.8);
        break;
      case 1:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height * 0.5);
        path.lineTo(size.width * 0.5, size.height);
        path.lineTo(0, size.height);
        break;
      default:
        path.moveTo(0, size.height);
        path.lineTo(0, size.height * 0.3);
        path.lineTo(size.width * 0.5, 0);
        path.lineTo(size.width, size.height * 0.3);
        path.lineTo(size.width, size.height);
        break;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
