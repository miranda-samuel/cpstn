import 'package:flutter/material.dart';

class PhpLevel1 extends StatefulWidget {
  const PhpLevel1({super.key});

  @override
  State<PhpLevel1> createState() => _PhpLevel1State();
}

class _PhpLevel1State extends State<PhpLevel1> {
  final List<String> codeBlocks = [
    '<?php',
    'echo "Hello World";',
    '?>'
  ];

  List<String> droppedBlocks = [];

  void checkAnswer() {
    String answer = droppedBlocks.join(' ');
    String correctAnswer = '<?php echo "Hello World"; ?>';

    if (answer == correctAnswer) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("✅ Correct!"),
          content: Text("Tama! Great job, PHP developer!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Proceed to next level later
              },
              child: Text("Finish"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PHP - Level 1"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '👉 Arrange the blocks to print "Hello World" in PHP:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Drop zone
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DragTarget<String>(
                builder: (context, candidateData, rejectedData) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: droppedBlocks.length,
                    itemBuilder: (context, index) {
                      return codeBlock(droppedBlocks[index]);
                    },
                  );
                },
                onAccept: (data) {
                  setState(() {
                    droppedBlocks.add(data);
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Draggable blocks
            Wrap(
              spacing: 10,
              children: codeBlocks.map((block) {
                return Draggable<String>(
                  data: block,
                  feedback: codeBlock(block),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: codeBlock(block),
                  ),
                  child: codeBlock(block),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: checkAnswer,
              child: Text("Run Code"),
            ),
            TextButton(
              onPressed: () => setState(() => droppedBlocks.clear()),
              child: Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }

  Widget codeBlock(String text) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
