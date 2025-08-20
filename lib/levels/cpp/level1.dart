import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'level2.dart';


class CppLevel1 extends StatefulWidget {
  const CppLevel1({super.key});

  @override
  State<CppLevel1> createState() => _CppLevel1State();
}

class _CppLevel1State extends State<CppLevel1> {
  List<String> codeBlocks = [
    'cout',
    '<<',
    '"Hello World";',
    'main()',
    'int',
    '#include <iostream>',
    '{',
    '}',
    'std::',
    'printf',
    'return 0;'
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
    loadScore(); // load if already saved
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
            title: Text("⏰ Time's up!"),
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
  }

  Future<void> saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Cpp_level1_score', score);
  }

  Future<void> loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('Cpp_level1_score') ?? 3;
    });
  }

  void checkAnswer() {
    String answer = droppedBlocks.join(' ');
    String correctAnswer = 'cout << "Hello World";';

    if (answer == correctAnswer) {
      timer?.cancel();
      saveScore(); // Save score
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("✅ Correct!"),
          content: Text("Nice one Totoy! You printed Hello World in C++."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CppLevel2()),
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
      }

      if (score <= 0) {
        timer?.cancel();
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
          SnackBar(content: Text("❌ Incorrect! -1 point")),
        );
      }
    }
  }

  void resetGame() {
    setState(() {
      droppedBlocks.clear();
      codeBlocks = [
        'cout',
        '<<',
        '"Hello World";',
        'main()',
        'int',
        '#include <iostream>',
        '{',
        '}',
        'std::',
        'printf',
        'return 0;'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("💻 C++ - Level 1"),
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
            Text("📖 Short Story", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text(
              isTagalog
                  ? 'Si Totoy ay nagsisimula sa C++! Gusto niyang i-print ang "Hello World" gamit ang tamang syntax. Tulungan mo siyang buuin ang tamang code: cout << "Hello World";'
                  : 'Totoy is starting to learn C++! He wants to print "Hello World" using the correct syntax. Help him build the correct code: cout << "Hello World";',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              isTagalog
                  ? '🧩 Ayusin ang mga blocks para mabuo: cout << "Hello World";'
                  : '🧩 Arrange to print: cout << "Hello World";',
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
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: codeBlock(block, Colors.blueAccent),
                  ),
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
}
