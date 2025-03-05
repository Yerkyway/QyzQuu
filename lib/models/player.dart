import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Player {
  final String type; // 'boy' or 'girl'
  double x;
  double y;
  double speed;
  bool isMoving;

  Player({
    required this.type,
    required this.x,
    required this.y,
    this.speed = 5.0,
    this.isMoving = false,
  });

  void move(Size size) {
    if (isMoving) {
      y -= speed; // Move upward
      // Keep player within bounds
      if (y < 0) y = 0;
      if (y > size.height) y = size.height;
    }
  }
}

class PlayerPainter extends CustomPainter {
  final Player player;
  final ui.Image boyImage;
  final ui.Image girlImage;

  PlayerPainter({
    required this.player,
    required this.boyImage,
    required this.girlImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final image = player.type == 'boy' ? boyImage : girlImage;
    final playerSize =
        size.width * 0.25; // Increased from 0.15 to 0.25 (25% of road width)

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(player.x, player.y, playerSize, playerSize),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(PlayerPainter oldDelegate) =>
      player.x != oldDelegate.player.x || player.y != oldDelegate.player.y;
}
