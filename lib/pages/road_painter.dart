import 'package:flutter/material.dart';

class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawGrass(canvas, size);
    _drawRoad(canvas, size);
    _drawStartFinishLines(canvas, size);
    _drawLaneMarkings(canvas, size);
    _drawStops(canvas, size);
  }

  void _drawGrass(Canvas canvas, Size size) {
    final Paint grassPaint = Paint()..color = Colors.green.shade600;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
  }

  void _drawRoad(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.8;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint roadPaint = Paint()..color = Colors.grey.shade800;

    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadWidth, size.height),
      roadPaint,
    );
  }

  void _drawStartFinishLines(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.8;
    final double roadLeft = (size.width - roadWidth) / 2;
    const double lineHeight = 10;

    final Paint finishPaint1 = Paint()..color = Colors.white;
    final Paint finishPaint2 = Paint()..color = Colors.black;

    for (double i = 0; i < roadWidth; i += 20) {
      canvas.drawRect(Rect.fromLTWH(roadLeft + i, 20, 10, lineHeight), finishPaint1);
      canvas.drawRect(Rect.fromLTWH(roadLeft + i + 10, 20, 10, lineHeight), finishPaint2);
    }

    for (double i = 0; i < roadWidth; i += 20) {
      canvas.drawRect(Rect.fromLTWH(roadLeft + i, size.height - 40, 10, lineHeight), finishPaint1);
      canvas.drawRect(Rect.fromLTWH(roadLeft + i + 10, size.height - 40, 10, lineHeight), finishPaint2);
    }
  }

  void _drawLaneMarkings(Canvas canvas, Size size) {
    final Paint dashedLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(size.width / 2, i),
        Offset(size.width / 2, i + 20),
        dashedLinePaint,
      );
    }
  }

  void _drawStops(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.8;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint stopPaint = Paint()..color = Colors.red;
    const double stopRadius = 40;
    final double stopSpacing = size.height / 7;

    for (var i = 1; i <= 5; i++) {
      double yPos = i * stopSpacing;
      canvas.drawCircle(Offset(roadLeft + roadWidth * 0.33, yPos), stopRadius, stopPaint);
      canvas.drawCircle(Offset(roadLeft + roadWidth * 0.67, yPos), stopRadius, stopPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
