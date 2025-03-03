import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Screen'),
      ),
      body: CustomPaint(
        painter: GrassPainter(),
        child: Container(),
      ),
    );
  }
}

class GrassPainter extends CustomPainter {
  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrass(canvas, size);
    _drawRoad(canvas, size);
    _drawStartFinishLines(canvas, size);

    for (int i = 0; i < 50; i++) {
      _drawFlower(canvas, size);
    }
  }

  void _drawGrass(Canvas canvas, Size size) {
    final Paint grassPaint = Paint()..color = Colors.green.shade600;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
  }

  void _drawRoad(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.2; // Road now takes 30% of the width
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint roadPaint = Paint()..color = Colors.grey.shade800;

    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadWidth, size.height),
      roadPaint,
    );
  }

  void _drawStartFinishLines(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.2;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    // Draw start line at the bottom
    canvas.drawLine(Offset(roadLeft, size.height * 0.9),
        Offset(roadLeft + roadWidth, size.height * 0.9), linePaint);

    // Draw finish line at the top
    canvas.drawLine(Offset(roadLeft, size.height * 0.1),
        Offset(roadLeft + roadWidth, size.height * 0.1), linePaint);
  }

  void _drawFlower(Canvas canvas, Size size) {
    final double x = random.nextDouble() * size.width;
    final double y = random.nextDouble() * size.height;
    final double flowerSize = 10 + random.nextDouble() * 10;

    // Avoid drawing flowers on the road
    final double roadWidth = size.width * 0.3;
    final double roadLeft = (size.width - roadWidth) / 2;
    if (x > roadLeft && x < roadLeft + roadWidth) {
      return;
    }

    final Paint flowerCenter = Paint()..color = Colors.yellow;
    final Paint petalPaint = Paint()..color = Colors.pinkAccent;

    canvas.drawCircle(Offset(x, y), flowerSize / 3, flowerCenter);

    for (int i = 0; i < 5; i++) {
      double angle = (2 * pi / 5) * i;
      double dx = x + cos(angle) * flowerSize;
      double dy = y + sin(angle) * flowerSize;
      canvas.drawCircle(Offset(dx, dy), flowerSize / 3, petalPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
