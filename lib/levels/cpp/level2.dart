import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CppLevel2 extends StatefulWidget {
  const CppLevel2({super.key});

  @override
  State<CppLevel2> createState() => _CppLevel2State();
}

class _CppLevel2State extends State<CppLevel2> {
  List<String> codeBlocks = [
    'int',
    'main()',
    '{',
    'return 0;',
    '}'
  ]..shuffle();

  List<String> droppedBlocks = [];
  int score = 3;
  int timeLeft = 60;
  Timer? timer;
  bool isTagalog = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    loadScore();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          if (timeLeft == 30 && score > 0) score--;
        });
      } else {
        timer.cancel();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("⏰ ${isTagalog ? 'Tapos na ang oras' : 'Time\'s up!'}"),
            content: Text("${isTagalog ? 'Score' : 'Score'}: $score"),
            actions: [
              TextButton(
                onPressed: () {
                  resetGame();
                  Navigator.pop(context);
                },
                child: Text(isTagalog ? "Subukan muli" : "Retry"),
              )
            ],
          ),
        );
      }
    });
  }

  Future<void> saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Cpp_level2_score', score);
  }

  Future<void> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('Cpp_level2_score') ?? 3;
    });
  }

  void checkAnswer() {
    String answer = droppedBlocks.join(' ');
    String correctAnswer = 'int main() { return 0; }';

    if (answer == correctAnswer) {
      timer?.cancel();
      saveScore();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("✅ ${isTagalog ? 'Tama!' : 'Correct!'}"),
          content: Text(
            isTagalog
                ? 'Magaling! Nabuong tama ang function ng main.'
                : 'Nice work! You correctly built the main function.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Back to selection
              },
              child: Text(isTagalog ? "Bumalik" : "Back"),
            )
          ],
        ),
      );
    } else {
      if (score > 0) {
        setState(() {
          score--;
        });
      }

      if (score <= 0) {
        timer?.cancel();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("💀 Game Over"),
            content: Text(isTagalog
                ? "Nauubos ang iyong puntos, Totoy."
                : "You've lost all your points, Totoy."),
            actions: [
              TextButton(
                onPressed: () {
                  resetGame();
                  Navigator.pop(context);
                },
                child: Text(isTagalog ? "Subukan Muli" : "Retry"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${isTagalog ? 'Mali! -1 puntos' : 'Incorrect! -1 point'}")),
        );
      }
    }
  }

  void resetGame() {
    setState(() {
      droppedBlocks.clear();
      codeBlocks = [
        'int',
        'main()',
        '{',
        'return 0;',
        '}'
      ]..shuffle();
      score = 3;
      timeLeft = 60;
    });
    timer?.cancel();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget codeBlock(String text, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("💻 C++ - Level 2"),
        backgroundColor: Colors.blueGrey,
        actions: [
          Row(
            children: [
              Icon(Icons.translate),
              Switch(
                value: isTagalog,
                onChanged: (val) => setState(() => isTagalog = val),
              ),
              Icon(Icons.timer),
              SizedBox(width: 4),
              Text("$timeLeft"),
              SizedBox(width: 16),
              Icon(Icons.star, color: Colors.yellow),
              Text(" $score", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📖 ${isTagalog ? 'Maikling Kwento' : 'Short Story'}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              isTagalog
                  ? 'Ngayon ay nais ni Totoy buuin ang pinaka-importanteng parte ng C++ program: ang `main()` function! Tulungan siyang buuin ito ng tama: int main() { return 0; }'
                  : 'Totoy now wants to build the most important part of a C++ program: the `main()` function! Help him assemble it correctly: int main() { return 0; }',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              isTagalog
                  ? '🧩 Ayusin ang mga blocks para mabuo: int main() { return 0; }'
                  : '🧩 Arrange to print: int main() { return 0; }',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              height: 140,
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.blueGrey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: droppedBlocks.map((block) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              droppedBlocks.remove(block);
                              codeBlocks.add(block);
                            });
                          },
                          child: codeBlock(block, Colors.greenAccent),
                        );
                      }).toList(),
                    ),
                  );
                },
                onAccept: (data) {
                  setState(() {
                    droppedBlocks.add(data);
                    codeBlocks.remove(data);
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            Text('📝 Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              color: Colors.grey[300],
              child: Text(
                droppedBlocks.join(' '),
                style: TextStyle(fontFamily: 'monospace', fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: codeBlocks.map((block) {
                return Draggable<String>(
                  data: block,
                  feedback: codeBlock(block, Colors.blueAccent),
                  childWhenDragging:
                  Opacity(opacity: 0.3, child: codeBlock(block, Colors.blueAccent)),
                  child: codeBlock(block, Colors.blueAccent),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: checkAnswer,
              icon: Icon(Icons.play_arrow),
              label: Text(isTagalog ? "Patakbuhin ang Code" : "Run Code"),
            ),
            TextButton(
              onPressed: resetGame,
              child: Text("🔁 ${isTagalog ? "Ulitin" : "Retry"}"),
            ),
          ],
        ),
      ),
    );
  }
}
