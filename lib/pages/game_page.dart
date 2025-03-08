import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Player boyPlayer;
  late Player girlPlayer;
  ui.Image? boyImage;
  ui.Image? girlImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    // Load boy image
    final boyData = await rootBundle.load('assets/boy_rider.png');
    final boyCodec = await ui.instantiateImageCodec(
      boyData.buffer.asUint8List(),
    );
    boyImage = (await boyCodec.getNextFrame()).image;

    // Load girl image
    final girlData = await rootBundle.load('assets/girl_rider.png');
    final girlCodec = await ui.instantiateImageCodec(
      girlData.buffer.asUint8List(),
    );
    girlImage = (await girlCodec.getNextFrame()).image;

    // Initialize players after images are loaded
    final size = MediaQuery.of(context).size;
    final roadWidth = size.width * 0.45;
    final roadLeft = (size.width - roadWidth) / 2;

    boyPlayer = Player(
      type: 'boy',
      x: roadLeft + roadWidth * 0.15,
      y: size.height * 0.75,
    );

    girlPlayer = Player(
      type: 'girl',
      x: roadLeft + roadWidth * 0.70,
      y: size.height * 0.75,
    );

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomPaint(
                  painter: GrassPainter(),
                  size: MediaQuery.of(context).size,
                ),
                if (boyImage != null && girlImage != null)
                  CustomPaint(
                    painter: PlayerPainter(
                      player: boyPlayer,
                      boyImage: boyImage!,
                      girlImage: girlImage!,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                if (boyImage != null && girlImage != null)
                  CustomPaint(
                    painter: PlayerPainter(
                      player: girlPlayer,
                      boyImage: boyImage!,
                      girlImage: girlImage!,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
              ],
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
    _drawStops(canvas, size);

    for (int i = 0; i < 50; i++) {
      _drawFlower(canvas, size);
    }
  }

  void _drawGrass(Canvas canvas, Size size) {
    final Paint grassPaint = Paint()..color = Colors.green.shade600;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
  }

  void _drawRoad(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.30;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint roadPaint = Paint()..color = Colors.grey.shade800;

    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadWidth, size.height),
      roadPaint,
    );
  }

  void _drawStartFinishLines(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.30;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    // Draw start line at the bottom
    canvas.drawLine(
      Offset(roadLeft, size.height * 0.95),
      Offset(roadLeft + roadWidth, size.height * 0.95),
      linePaint,
    );

    // Draw finish line at the top
    canvas.drawLine(
      Offset(roadLeft, size.height * 0.05),
      Offset(roadLeft + roadWidth, size.height * 0.05),
      linePaint,
    );
  }

  void _drawStops(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.30;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint stopPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Define stop positions along the road
    final List<double> stopPositions = [0.8, 0.6, 0.4, 0.2];

    for (double position in stopPositions) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height * position),
        roadWidth / 5, // Increased circle radius
        stopPaint,
      );
    }
  }

  void _drawFlower(Canvas canvas, Size size) {
    final double x = random.nextDouble() * size.width;
    final double y = random.nextDouble() * size.height;
    final double flowerSize = 10 + random.nextDouble() * 10;

    // Avoid drawing flowers on the road
    final double roadWidth = size.width * 0.45;
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
