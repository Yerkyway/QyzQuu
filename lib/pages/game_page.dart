import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../models/player.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Player boyPlayer;
  late Player girlPlayer;
  ui.Image? boyImage;
  ui.Image? girlImage;
  bool isLoading = true;
  late Ticker _ticker;

  // Add countdown variables
  bool showCountdown = true;
  int countdownValue = 3;
  Timer? countdownTimer;

  // Add lists to store circle positions
  List<double> boyCirclePositions = [];
  List<double> girlCirclePositions = [];
  double finishLineY = 0;

  // Track current target positions
  int boyTargetIndex = 0;
  int girlTargetIndex = 0;

  // Track if player is currently moving
  bool isBoyMoving = false;
  bool isGirlMoving = false;

  // Track if quiz is shown
  bool isQuizShown = false;
  String currentPlayer = 'girl';
  int currentQuestionIndex = 0;
  bool showResult = false;
  bool isCorrect = false;
  Timer? resultTimer;

  // Track game finish state
  bool isGameFinished = false;
  String winner = '';
  Timer? redirectTimer;

  // Track which questions have been answered (to avoid repeating)
  Set<String> answeredQuestions = {};

  // Movement speed
  final double moveSpeed = 5.0;

  // Add a timer for each question
  Timer? questionTimer;

  int questionTimeLeft = 10; // Track time left for the question

  bool isTimeout =
      false; // Track if the question was not answered due to timeout

  // Define separate question lists for boy and girl
  List<Question> boyQuestions = [
    // Add 5 questions for the boy player
    Question(
      text: "Қай жылы Қазақ хандығы құрылды?",
      options: ["1361 ж.", "1465 ж.", "1511 ж.", "1376 ж."],
      correctAnswerIndex: 1,
    ),
    Question(
      text:
          "1723-1727 жылдары қазақ халқына ауыр зардап әкелген оқиға қалай аталды?",
      options: [
        "Аңырақай шайқасы",
        "Қалмақ қырғыны",
        "Орбұлақ шайқасы",
        "Ақтабан шұбырынды, Алқакөл сұлама",
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "1837-1847 жылдары болған көтеріліске кім жетекшілік етті?",
      options: [
        "Сырым Датұлы",
        "Жанқожа Нұрмұхамедұлы",
        "Исатай Тайманұлы",
        "Кенесары Қасымұлы",
      ],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "'Жеті жарғы' заңдар жинағын кім әзірледі?",
      options: ["Есім хан", "Тәуке хан", "Әбілқайыр хан", "Қасым хан"],
      correctAnswerIndex: 3,
    ),
    Question(
      text: "1916 жылғы ұлт-азаттық көтерілістің негізгі себебі қандай болды?",
      options: [
        "Дінге қысым жасалуы",
        "Ресей патшасының 19-43 жас аралығындағы ер адамдарды майданға қара жұмысқа алу туралы жарлығы",
        "Салықтың көбеюі",
        "Қазақ жерінің тартып алынуы",
      ],
      correctAnswerIndex: 1,
    ),
  ];

  List<Question> girlQuestions = [
    // Add 5 questions for the girl player
    Question(
      text: "1936 жылы Қазақстан қай одақтас республикаға айналды?",
      options: [
        "Кеңестік Социалистік Республика",
        "Қазақ Кеңестік Социалистік Республикасы (Қазақ КСР)",
        "Қазақ АКСР",
        "Түркістан АКСР",
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақ КСР-нің алғашқы астанасы қай қала болды?",
      options: ["Орынбор", "Алматы", "Қызылорда", "Ақмола"],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "XX ғасырдың басында 'Алаш' партиясын кім басқарды?",
      options: [
        "Міржақып Дулатұлы",
        "Мұстафа Шоқай",
        "Ахмет Байтұрсынұлы",
        "Әлихан Бөкейхан",
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақстан тәуелсіздігін қашан жариялады?",
      options: [
        "1993 ж. 1 мамыр",
        "1990 ж. 25 қазан",
        "1986 ж. 16 желтоқсан",
        " 1991 ж. 16 желтоқсан",
      ],
      correctAnswerIndex: 3,
    ),
    Question(
      text:
          "1993 жылы Қазақстан Республикасының тұңғыш Конституциясы қай күні қабылданды?",
      options: ["28 қаңтар", "16 желтоқсан", "25 қазан", "30 тамыз"],
      correctAnswerIndex: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _ticker = createTicker(_onTick)..start();
    // Start countdown when page loads
    _startCountdown();
  }

  Future<void> _loadImages() async {
    final boyData = await rootBundle.load('assets/boy.png');
    final boyCodec = await ui.instantiateImageCodec(
      boyData.buffer.asUint8List(),
    );
    boyImage = (await boyCodec.getNextFrame()).image;

    final girlData = await rootBundle.load('assets/girl.png');
    final girlCodec = await ui.instantiateImageCodec(
      girlData.buffer.asUint8List(),
    );
    girlImage = (await girlCodec.getNextFrame()).image;

    final size = MediaQuery.of(context).size;
    final roadWidth = size.width * 0.8;
    final roadLeft = (size.width - roadWidth) / 2;

    // Initialize player positions at starting line
    boyPlayer = Player(
      type: 'boy',
      x: roadLeft + roadWidth * 0.33,
      y: size.height - 200, // Just above finish line
    );

    girlPlayer = Player(
      type: 'girl',
      x: roadLeft + roadWidth * 0.85,
      y: size.height - 200, // Just above finish line
    );

    // Calculate red circle positions
    final double stopSpacing = size.height / 7;
    finishLineY = 20.0; // Finish line Y position

    for (var i = 5; i >= 1; i--) {
      double yPos = i * stopSpacing;
      boyCirclePositions.add(yPos);
      girlCirclePositions.add(yPos);
    }

    // Sort positions from bottom to top
    boyCirclePositions.sort((a, b) => b.compareTo(a));
    girlCirclePositions.sort((a, b) => b.compareTo(a));

    setState(() {
      isLoading = false;
    });
  }

  void _onTick(Duration elapsed) {
    if (!isLoading) {
      setState(() {
        // Handle boy movement
        if (isBoyMoving) {
          double targetY = boyTargetIndex < boyCirclePositions.length
              ? boyCirclePositions[boyTargetIndex]
              : finishLineY;

          if ((boyPlayer.y - targetY).abs() > moveSpeed) {
            // Move towards target
            boyPlayer.y += (targetY < boyPlayer.y) ? -moveSpeed : moveSpeed;
          } else {
            // Arrived at target
            boyPlayer.y = targetY;
            isBoyMoving = false;

            // Check if reached finish line
            if (boyTargetIndex == boyCirclePositions.length &&
                boyPlayer.y <= finishLineY + moveSpeed) {
              _handleWinner('Ұл бала');
            }
            // Show question if reached a circle (not the finish line)
            else if (boyTargetIndex < boyCirclePositions.length) {
              // Create a unique identifier for this question
              String questionId = 'boy-$boyTargetIndex';

              // Only show the question if it hasn't been answered yet
              if (!answeredQuestions.contains(questionId)) {
                _showQuestionDialog('boy', boyTargetIndex);
              }
            }
          }
        }

        // Handle girl movement
        if (isGirlMoving) {
          double targetY = girlTargetIndex < girlCirclePositions.length
              ? girlCirclePositions[girlTargetIndex]
              : finishLineY;

          if ((girlPlayer.y - targetY).abs() > moveSpeed) {
            // Move towards target
            girlPlayer.y += (targetY < girlPlayer.y) ? -moveSpeed : moveSpeed;
          } else {
            // Arrived at target
            girlPlayer.y = targetY;
            isGirlMoving = false;

            // Check if reached finish line
            if (girlTargetIndex == girlCirclePositions.length &&
                girlPlayer.y <= finishLineY + moveSpeed) {
              _handleWinner('Қыз бала');
            }
            // Show question if reached a circle (not the finish line)
            else if (girlTargetIndex < girlCirclePositions.length) {
              // Create a unique identifier for this question
              String questionId = 'girl-$girlTargetIndex';

              // Only show the question if it hasn't been answered yet
              if (!answeredQuestions.contains(questionId)) {
                _showQuestionDialog('girl', girlTargetIndex);
              }
            }
          }
        }
      });
    }
  }

  void _handleWinner(String playerType) {
    if (!isGameFinished) {
      setState(() {
        isGameFinished = true;
        winner = playerType;
      });

      // Set timer to redirect after 5 seconds
      redirectTimer = Timer(const Duration(seconds: 5), () {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  void _showQuestionDialog(String player, int questionIndex) {
    // Don't show question if quiz is already showing or if game is finished
    if (isQuizShown || isGameFinished) return;

    // Check if we've run out of questions for this player
    List<Question> questionList =
        player == 'boy' ? boyQuestions : girlQuestions;
    if (questionIndex >= questionList.length) return;

    setState(() {
      isQuizShown = true;
      currentPlayer = player;
      currentQuestionIndex = questionIndex;
      questionTimeLeft = 10; // Reset the timer
    });

    // Start a 10-second timer for the question
    questionTimer?.cancel(); // Cancel any existing timer
    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (questionTimeLeft > 1) {
          questionTimeLeft--;
        } else {
          timer.cancel();
          _checkAnswer(-1); // Pass -1 to indicate timeout
        }
      });
    });
  }

  void _checkAnswer(int selectedAnswer) {
    // Clear any existing timers
    resultTimer?.cancel();
    questionTimer?.cancel(); // Cancel the question timer

    // Determine if the answer was due to a timeout
    isTimeout = selectedAnswer == -1;

    // Get the correct list of questions
    List<Question> questionList =
        currentPlayer == 'boy' ? boyQuestions : girlQuestions;

    bool correct = !isTimeout &&
        selectedAnswer == questionList[currentQuestionIndex].correctAnswerIndex;

    // Mark this question as answered regardless of correctness
    String questionId = '$currentPlayer-$currentQuestionIndex';
    answeredQuestions.add(questionId);

    setState(() {
      showResult = true;
      isCorrect = correct;
    });

    // Set timer to handle the next action after showing the result
    resultTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        isQuizShown = false;
        showResult = false;

        if (correct) {
          // If answer was correct, move the current player forward
          if (currentPlayer == 'boy') {
            boyTargetIndex = 0; // Ensure starting at the first stop
            isBoyMoving = true;
          } else {
            girlTargetIndex = 0; // Ensure starting at the first stop
            isGirlMoving = true;
          }

          // Wait for movement to complete before showing next question
          Timer(const Duration(milliseconds: 500), () {
            // Switch to the other player's turn
            currentPlayer = currentPlayer == 'boy' ? 'girl' : 'boy';
            if (currentPlayer == 'boy') {
              _showQuestionDialog('boy', boyTargetIndex);
            } else {
              _showQuestionDialog('girl', girlTargetIndex);
            }
          });
        } else {
          // If answer was incorrect, immediately show question for other player
          currentPlayer = currentPlayer == 'boy' ? 'girl' : 'boy';
          if (currentPlayer == 'boy') {
            _showQuestionDialog('boy', boyTargetIndex);
          } else {
            _showQuestionDialog('girl', girlTargetIndex);
          }
        }
      });
    });
  }

  void _startCountdown() {
    setState(() {
      showCountdown = true;
      countdownValue = 3;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownValue > 1) {
          countdownValue--;
        } else {
          showCountdown = false;
          timer.cancel();
          // Show girl's question immediately after countdown
          _showQuestionDialog('girl', 0);
        }
      });
    });
  }

  @override
  void dispose() {
    resultTimer?.cancel();
    redirectTimer?.cancel();
    countdownTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    CustomPaint(
                      painter: RoadPainter(),
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
                    // Positioned(
                    //   left: 20,
                    //   bottom: 20,
                    //   child: ElevatedButton(
                    //     onPressed: isGameFinished ? null : _moveBoyToNextTarget,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.blue,
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 20, vertical: 10),
                    //     ),
                    //     child: const Text("Move Boy",
                    //         style: TextStyle(color: Colors.white)),
                    //   ),
                    // ),
                    // Positioned(
                    //   right: 20,
                    //   bottom: 20,
                    //   child: ElevatedButton(
                    //     onPressed: isGameFinished ? null : _moveGirlToNextTarget,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.red,
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 20, vertical: 10),
                    //     ),
                    //     child: const Text("Move Girl",
                    //         style: TextStyle(color: Colors.white)),
                    //   ),
                    // ),
                    // Quiz overlay
                    if (isQuizShown) _buildQuizOverlay(),

                    // Winner overlay
                    if (isGameFinished) _buildWinnerOverlay(),

                    // Add countdown overlay
                    if (showCountdown)
                      Container(
                        color: Colors.black54,
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Game Starting in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                countdownValue.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildQuizOverlay() {
    // Get the correct list of questions
    List<Question> questionList =
        currentPlayer == 'boy' ? boyQuestions : girlQuestions;
    final Question question = questionList[currentQuestionIndex];

    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: showResult
              ? _buildResultContent()
              : _buildQuestionContent(question),
        ),
      ),
    );
  }

  Widget _buildQuestionContent(Question question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Stop ${currentQuestionIndex + 1} - ${currentPlayer.capitalize()}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: currentPlayer == 'boy' ? Colors.blue : Colors.red,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          question.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Time left: ${questionTimeLeft}s',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ...List.generate(question.options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton(
              onPressed: () => _checkAnswer(index),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey.shade200,
              ),
              child: Text(
                "${String.fromCharCode(65 + index)}) ${question.options[index]}",
                style: const TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.left,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? Colors.green : Colors.red,
          size: 80,
        ),
        const SizedBox(height: 20),
        Text(
          isCorrect ? "Correct!" : (isTimeout ? "Not Answered!" : "Incorrect!"),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isCorrect
              ? "Moving to the next stop in 3 seconds..."
              : "Try again! Press the move button to continue.",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWinnerOverlay() {
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: winner == 'Boy' ? Colors.blue : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                "Congratulations!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: winner == 'Boy' ? Colors.blue : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$winner wins the race!",
                style: const TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Returning to main menu in 5 seconds...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

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
    final double roadWidth = size.width * 0.6;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint roadPaint = Paint()
      ..color = const ui.Color.fromARGB(255, 145, 115, 74);

    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadWidth, size.height),
      roadPaint,
    );
  }

  void _drawStartFinishLines(Canvas canvas, Size size) {
    final double roadWidth = size.width * 0.6;
    final double roadLeft = (size.width - roadWidth) / 2;
    const double lineHeight = 10;

    final Paint finishPaint1 = Paint()..color = Colors.white;
    final Paint finishPaint2 = Paint()..color = Colors.black;

    for (double i = 0; i < roadWidth; i += 20) {
      canvas.drawRect(
        Rect.fromLTWH(roadLeft + i, 20, 10, lineHeight),
        finishPaint1,
      );
      canvas.drawRect(
        Rect.fromLTWH(roadLeft + i + 10, 20, 10, lineHeight),
        finishPaint2,
      );
    }

    // for (double i = 0; i < roadWidth; i += 20) {
    //   canvas.drawRect(
    //       Rect.fromLTWH(roadLeft + i, size.height - 40, 10, lineHeight),
    //       finishPaint1);
    //   canvas.drawRect(
    //       Rect.fromLTWH(roadLeft + i + 10, size.height - 40, 10, lineHeight),
    //       finishPaint2);
    // }
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
    final Paint stopPaint = Paint()
      ..color = const ui.Color.fromARGB(255, 240, 60, 24);
    const double stopRadius = 40;
    final double stopSpacing = size.height / 7;

    for (var i = 1; i <= 5; i++) {
      double yPos = i * stopSpacing;
      canvas.drawCircle(
        Offset(roadLeft + roadWidth * 0.5, yPos),
        stopRadius,
        stopPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PlayerPainter extends CustomPainter {
  final Player player;
  final ui.Image boyImage;
  final ui.Image girlImage;
  final double scaleFactor;

  PlayerPainter({
    required this.player,
    required this.boyImage,
    required this.girlImage,
    this.scaleFactor = 0.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final image = player.type == 'boy' ? boyImage : girlImage;

    final double newWidth = image.width * scaleFactor;
    final double newHeight = image.height * scaleFactor;

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect dstRect = Rect.fromLTWH(
      player.x - newWidth / 2,
      player.y - newHeight / 2,
      newWidth,
      newHeight,
    );

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
