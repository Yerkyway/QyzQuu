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

  // Game parameters
  bool showCountdown = true;
  int countdownValue = 3;
  Timer? countdownTimer;
  double roadLengthMultiplier = 3.0;
  double visibleAreaHeight = 0;
  double scrollOffset = 0;

  // Game state
  List<double> boyCirclePositions = [];
  List<double> girlCirclePositions = [];
  double finishLineY = 0;
  int boyTargetIndex = -1;
  int girlTargetIndex = -1;
  bool isBoyMoving = false;
  bool isGirlMoving = false;
  bool isQuizShown = false;
  String currentPlayer = 'girl';
  int currentQuestionIndex = 0;
  bool showResult = false;
  bool isCorrect = false;
  bool isGameFinished = false;
  String winner = '';
  Set<String> answeredQuestions = {};
  double moveSpeed = 5.0;
  Timer? resultTimer;
  Timer? redirectTimer;
  Timer? questionTimer;
  int questionTimeLeft = 30;
  bool isTimeout = false;

  // Questions (add your questions here)
  List<Question> boyQuestions = [
    Question(
      text: "Қазақ халқының дәстүрлі жыл санауында неше жыл бар?",
      options: ["10 жыл", "12 жыл", "15 жыл", "20 жыл"],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Абылай ханның шын есімі кім?",
      options: ["Әбілмансұр", "Тәуекел", "Қасым", "Жәнібек"],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "Алаш қозғалысының басты мақсаты не болды?",
      options: [
        "Қазақстанды Ресей құрамында сақтау",
        "Қазақ мемлекеттілігін қалпына келтіру",
        "Ислам дінін тарату",
        "Көшпелі өмір салтын дамыту"
      ],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Қазақстан тәуелсіздігін қай жылы алды?",
      options: ["1986 ж.", "1991 ж.", "1993 ж.", "1995 ж."],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Елтаңба авторлары кімдер?",
      options: [
        "Шот-Аман Уалиханов пен Жандарбек Мәлібеков",
        "Қасымхан Жандарбеков пен Тұрар Рысқұлов",
        "Әбілхан Қастеев пен Дінмұхамед Қонаев",
        "Мұхтар Әуезов пен Сәкен Сейфуллин"
      ],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "Қазақ даласында алғаш мектеп ашқан ағартушы кім?",
      options: [
        "Ахмет Байтұрсынұлы",
        "Ыбырай Алтынсарин",
        "Шоқан Уәлиханов",
        "Абай Құнанбаев"
      ],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Махамбет Өтемісұлы кімнің серігі болған?",
      options: [
        "Кенесары Қасымұлы",
        "Жанқожа Нұрмұхамедұлы",
        "Исатай Тайманұлы",
        "Сырым Датұлы"
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақтың тұңғыш ғарышкері кім?",
      options: [
        "Талғат Мұсабаев",
        "Айдын Айымбетов",
        "Юрий Гагарин",
        "Тоқтар Әубәкіров"
      ],
      correctAnswerIndex: 3,
    ),
    Question(
      text: "ҚР Ата Заңы (Конституциясы) қай жылы қабылданды?",
      options: ["1991 ж.", "1993 ж.", "1995 ж.", "1997 ж."],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақ хандығының негізін қалаған хандар кімдер?",
      options: [
        "Тәуке хан мен Абылай хан",
        "Есім хан мен Жәңгір хан",
        "Керей мен Жәнібек",
        "Қасым хан мен Хақназар хан"
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақ хандығы қай жылы құрылды?",
      options: ["1361 ж.", "1465 ж.", "1511 ж.", "1376 ж."],
      correctAnswerIndex: 1,
    ),
    // География
    Question(
      text: "Қазақстанның ең биік нүктесі қайсы?",
      options: ["Хан-Тәңірі", "Белуха", "Эльбрус", "Тянь-Шань"],
      correctAnswerIndex: 0,
    ),
    // Математика
    Question(
      text: "3^3 + 2^3 = ?",
      options: ["35", "27", "32", "35"],
      correctAnswerIndex: 2,
    ),
    // Физика
    Question(
      text: "Электр тогын жақсы өткізетін металл қайсы?",
      options: ["Мыс", "Алюминий", "Күміс", "Темір"],
      correctAnswerIndex: 2,
    ),
    // Химия
    Question(
      text: "Судың химиялық формуласы қандай?",
      options: ["H2O", "O2", "CO2", "H2SO4"],
      correctAnswerIndex: 0,
    ),
    // Биология
    Question(
      text: "Адам ағзасындағы ең үлкен орган қандай?",
      options: ["Жүрек", "Миға", "Тері", "Өкпе"],
      correctAnswerIndex: 2,
    ),
    // Әдебиет
    Question(
      text: "Абай Құнанбаевтың шын есімі кім?",
      options: ["Ибраһим", "Құнанбай", "Әбіш", "Семей"],
      correctAnswerIndex: 0,
    ),
    // Астрономия
    Question(
      text: "Күн жүйесіндегі ең үлкен планета қайсы?",
      options: ["Марс", "Шолпан", "Юпитер", "Сатурн"],
      correctAnswerIndex: 2,
    ),
    // Информатика
    Question(
      text: "1 байт қанша биттен тұрады?",
      options: ["8", "16", "32", "64"],
      correctAnswerIndex: 0,
    ),
    // Қазақ тілі
    Question(
      text: "'Кітап' сөзінің синонимі қайсы?",
      options: ["Қалам", "Әңгіме", "Том", "Құжат"],
      correctAnswerIndex: 2,
    ),
  ];

  List<Question> girlQuestions = [
    Question(
      text: "Қазақ хандығының ең алғашқы ханы кім?",
      options: ["Абылай хан", "Керей хан", "Жәнібек хан", "Қасым хан"],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Қазақ халқының дәстүрлі баспанасы қалай аталады?",
      options: ["Киіз үй", "Сарай", "Көшпелі үй", "Жертөле"],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "1913 жылы 'Қазақ' газетін кім шығарды?",
      options: [
        "Әлихан Бөкейхан",
        "Ахмет Байтұрсынұлы",
        "Міржақып Дулатұлы",
        "Сәкен Сейфуллин"
      ],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Ұлы Отан соғысында ерлік көрсеткен қазақ қыздарын атаңыз.",
      options: [
        "Әлия Молдағұлова мен Мәншүк Мәметова",
        "Роза Бағланова мен Қамар Сәлімбаева",
        "Фариза Оңғарсынова мен Зейнолла Қабдолов",
        "Бибігүл Төлегенова мен Ғабит Мүсірепов"
      ],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "Қазақтың тұңғыш романисі кім?",
      options: [
        "Сәкен Сейфуллин",
        "Бейімбет Майлин",
        "Міржақып Дулатұлы",
        "Ахмет Байтұрсынұлы"
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақтың атақты күйші-композиторы кім?",
      options: ["Құрманғазы", "Абай", "Жамбыл", "Сүйінбай"],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "Томирис кім болған?",
      options: [
        "Қазақ ханы",
        "Сақтардың патшайымы",
        "Қыпшақ билеушісі",
        "Алтын Орда ханы"
      ],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Қазақтың алғашқы әйел дәрігері кім?",
      options: [
        "Дина Нұрпейісова",
        "Роза Бағланова",
        "Аққағаз Досжанова",
        "Фатима Ғабитова"
      ],
      correctAnswerIndex: 2,
    ),
    Question(
      text: "Қазақстанның қазіргі астанасы қай қала?",
      options: ["Алматы", "Астана", "Шымкент", "Ақтөбе"],
      correctAnswerIndex: 1,
    ),
    Question(
      text: "Абай Құнанбаевтың шын есімі кім?",
      options: ["Ибраһим", "Құнанбай", "Әбіш", "Семей"],
      correctAnswerIndex: 0,
    ),
    Question(
      text: "Қазақстан тәуелсіздігін қай жылы алды?",
      options: ["1986 ж.", "1991 ж.", "1993 ж.", "1995 ж."],
      correctAnswerIndex: 1,
    ),
    // География
    Question(
      text: "Каспий теңізі қандай су айдынына жатады?",
      options: ["Өзен", "Көл", "Теңіз", "Мұхит"],
      correctAnswerIndex: 1,
    ),
    // Математика
    Question(
      text: "√49 мәні қандай?",
      options: ["5", "6", "7", "8"],
      correctAnswerIndex: 2,
    ),
    // Физика
    Question(
      text: "Заттың ең кішкентай бөлшегі не?",
      options: ["Молекула", "Атом", "Протон", "Нейтрон"],
      correctAnswerIndex: 1,
    ),
    // Химия
    Question(
      text: "Алтынның химиялық белгісі қандай?",
      options: ["Al", "Ag", "Fe", "Au"],
      correctAnswerIndex: 3,
    ),
    // Биология
    Question(
      text: "Қан тобының түрлері қанша?",
      options: ["2", "3", "4", "5"],
      correctAnswerIndex: 2,
    ),
    // Әдебиет
    Question(
      text: "Қазақтың тұңғыш романы қалай аталады?",
      options: [
        "Абай жолы",
        "Қараш-Қараш оқиғасы",
        "Бақытсыз Жамал",
        "Көшпенділер"
      ],
      correctAnswerIndex: 2,
    ),
    // Астрономия
    Question(
      text: "Айдың Жерді толық айналып шығу уақыты қандай?",
      options: ["24 сағат", "7 күн", "28 күн", "365 күн"],
      correctAnswerIndex: 2,
    ),
    // Информатика
    Question(
      text: "Компьютердің негізгі құрылғылары қандай?",
      options: [
        "Пернетақта, монитор, тышқан",
        "Процессор, жедел жады, қатқыл диск",
        "Принтер, сканер, микрофон",
        "Бағдарламалар, операциялық жүйе, файлдар"
      ],
      correctAnswerIndex: 1,
    ),
    // Қазақ тілі
    Question(
      text: "'Жүзеге асыру' тіркесінің синонимін таңдаңыз.",
      options: ["Орындау", "Жою", "Алу", "Көшіру"],
      correctAnswerIndex: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _ticker = createTicker(_onTick)..start();
    _startCountdown();
  }

  Future<void> _loadImages() async {
    final boyData = await rootBundle.load('assets/boy.png');
    final boyCodec =
        await ui.instantiateImageCodec(boyData.buffer.asUint8List());
    boyImage = (await boyCodec.getNextFrame()).image;

    final girlData = await rootBundle.load('assets/girl.png');
    final girlCodec =
        await ui.instantiateImageCodec(girlData.buffer.asUint8List());
    girlImage = (await girlCodec.getNextFrame()).image;

    final size = MediaQuery.of(context).size;
    visibleAreaHeight = size.height;
    final double totalRoadLength = visibleAreaHeight * roadLengthMultiplier;
    final double roadWidth = size.width * 0.9;
    final double roadLeft = (size.width - roadWidth) / 2;

    boyPlayer = Player(
      type: 'boy',
      x: roadLeft + roadWidth * 0.35,
      y: totalRoadLength - 70,
    );

    girlPlayer = Player(
      type: 'girl',
      x: roadLeft + roadWidth * 0.75,
      y: totalRoadLength - 70,
    );

    final double stopSpacing = totalRoadLength / 11;
    for (var i = 10; i >= 1; i--) {
      double yPos = i * stopSpacing;
      boyCirclePositions.add(yPos);
      girlCirclePositions.add(yPos);
    }
    boyCirclePositions.sort((a, b) => b.compareTo(a));
    girlCirclePositions.sort((a, b) => b.compareTo(a));

    finishLineY = 20.0;

    setState(() => isLoading = false);
  }

  void _onTick(Duration elapsed) {
    if (!isLoading) {
      double targetScroll =
          (boyPlayer.y + girlPlayer.y) / 2 - visibleAreaHeight / 2;
      scrollOffset = scrollOffset * 0.9 + targetScroll * 0.1;

      double interpolationFactor = 0.9; // Smooth following
      if (isQuizShown) {
        // Center the current player when quiz is shown
        Player activePlayer = currentPlayer == 'boy' ? boyPlayer : girlPlayer;
        targetScroll = activePlayer.y - visibleAreaHeight / 2;
        interpolationFactor = 0.1; // Snap faster to the target
      } else {
        // Follow both players normally
        targetScroll = (boyPlayer.y + girlPlayer.y) / 2 - visibleAreaHeight / 2;
        interpolationFactor = 0.9; // Smooth following
      }

      scrollOffset = scrollOffset * interpolationFactor +
          targetScroll * (1 - interpolationFactor);

      setState(() {
        _updatePlayerPosition(
            boyPlayer, boyCirclePositions, isBoyMoving, boyTargetIndex, 'boy');
        _updatePlayerPosition(girlPlayer, girlCirclePositions, isGirlMoving,
            girlTargetIndex, 'girl');
      });
    }
  }

  void _updatePlayerPosition(Player player, List<double> circles, bool isMoving,
      int targetIndex, String type) {
    if (isMoving) {
      double targetY =
          targetIndex < circles.length ? circles[targetIndex] : finishLineY;
      if ((player.y - targetY).abs() > moveSpeed) {
        player.y += (targetY < player.y) ? -moveSpeed : moveSpeed;
      } else {
        player.y = targetY;
        _handleArrival(player, type, targetIndex);
      }
    }
  }

  void _handleArrival(Player player, String type, int targetIndex) {
    setState(() {
      if (type == 'boy') {
        isBoyMoving = false;
        boyTargetIndex = targetIndex;
      } else {
        isGirlMoving = false;
        girlTargetIndex = targetIndex;
      }
    });

    if (player.y <= finishLineY + moveSpeed) {
      _handleWinner(type == 'boy' ? 'Ұл бала' : 'Қыз бала');
    } else if (targetIndex <
        (type == 'boy'
            ? boyCirclePositions.length
            : girlCirclePositions.length)) {
      String questionId = '$type-$targetIndex';
      if (!answeredQuestions.contains(questionId)) {
        _showQuestionDialog(type, targetIndex);
      }
    }
  }

  void _showQuestionDialog(String player, int questionIndex) {
    if (isQuizShown || isGameFinished) return;

    List<Question> questionList =
        player == 'boy' ? boyQuestions : girlQuestions;
    if (questionIndex >= questionList.length) return;

    setState(() {
      isQuizShown = true;
      currentPlayer = player;
      currentQuestionIndex = questionIndex;
      questionTimeLeft = 30;
    });

    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (questionTimeLeft > 1) {
          questionTimeLeft--;
        } else {
          timer.cancel();
          _checkAnswer(-1);
        }
      });
    });
  }

  void _checkAnswer(int selectedAnswer) {
    resultTimer?.cancel();
    questionTimer?.cancel();

    isTimeout = selectedAnswer == -1;
    bool correct = !isTimeout &&
        selectedAnswer ==
            (currentPlayer == 'boy'
                ? boyQuestions[currentQuestionIndex].correctAnswerIndex
                : girlQuestions[currentQuestionIndex].correctAnswerIndex);

    String questionId = '$currentPlayer-$currentQuestionIndex';
    answeredQuestions.add(questionId);

    setState(() {
      showResult = true;
      isCorrect = correct;
    });

    resultTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        isQuizShown = false;
        showResult = false;

        if (correct) {
          if (currentPlayer == 'boy') {
            boyTargetIndex++;
            isBoyMoving = true;
          } else {
            girlTargetIndex++;
            isGirlMoving = true;
          }

          Timer(const Duration(milliseconds: 2000), () {
            currentPlayer = currentPlayer == 'boy' ? 'girl' : 'boy';
            if (currentPlayer == 'boy') {
              _showQuestionDialog('boy', boyTargetIndex + 1);
            } else {
              _showQuestionDialog('girl', girlTargetIndex + 1);
            }
          });
        } else {
          currentPlayer = currentPlayer == 'boy' ? 'girl' : 'boy';
          _showQuestionDialog(
              currentPlayer,
              currentPlayer == 'boy'
                  ? boyTargetIndex + 1
                  : girlTargetIndex + 1);
        }
      });
    });
  }

  void _startCountdown() {
    setState(() {
      showCountdown = true;
      countdownValue = 5;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownValue > 1) {
          countdownValue--;
        } else {
          showCountdown = false;
          timer.cancel();
          _showQuestionDialog('girl', 0);
        }
      });
    });
  }

  void _handleWinner(String playerType) {
    if (!isGameFinished) {
      setState(() {
        isGameFinished = true;
        winner = playerType;
      });

      redirectTimer = Timer(const Duration(seconds: 5), () {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    countdownTimer?.cancel();
    questionTimer?.cancel();
    resultTimer?.cancel();
    redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Stack(
              children: [
                CustomPaint(
                  painter: RoadPainter(
                    roadLength: visibleAreaHeight * roadLengthMultiplier,
                    scrollOffset: scrollOffset,
                  ),
                  size: MediaQuery.of(context).size,
                ),
                if (boyImage != null && girlImage != null) ...[
                  _buildPlayer(boyPlayer, boyImage!),
                  _buildPlayer(girlPlayer, girlImage!),
                ],
                if (isQuizShown) _buildQuizOverlay(),
                if (isGameFinished) _buildWinnerOverlay(),
                if (showCountdown) _buildCountdownOverlay(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlayer(Player player, ui.Image image) {
    return Transform.translate(
      offset: Offset(0, -scrollOffset),
      child: CustomPaint(
        painter: PlayerPainter(
          player: player,
          image: image,
          scaleFactor: 0.6,
        ),
      ),
    );
  }

  Widget _buildQuizOverlay() {
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
          isCorrect
              ? "Дұрыс!"
              : (isTimeout ? "Жауап берілмеді!" : "Дұрыс емес!"),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isCorrect
              ? "Келесі аялдамаға 3 секундтан кейін қозғаламыз..."
              : "Қайтадан көріңіз! ",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuestionContent(Question question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currentPlayer == 'boy' ? 'Ұл бала' : 'Қыз бала',
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
          'Қалған уақыт: ${questionTimeLeft}s',
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
                "Құттықтаймыз!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: winner == 'Boy' ? Colors.blue : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Жеңімпаз жарыста жеңіске жетті",
                style: const TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "5 секундтан кейін басты мәзірге ораламыз...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ойын басталып жатыр',
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
    );
  }
}

class RoadPainter extends CustomPainter {
  final double roadLength;
  final double scrollOffset;

  RoadPainter({required this.roadLength, required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, -scrollOffset);
    final Paint grassPaint = Paint()..color = Colors.green.shade600;
    canvas.drawRect(
      Rect.fromLTWH(
          0,
          -size.height * 5, // Extend 5 screen heights above
          size.width,
          size.height * 15 // Cover 15 total screen heights
          ),
      grassPaint,
    );

    final double roadWidth = size.width * 0.6;
    final double roadLeft = (size.width - roadWidth) / 2;
    final Paint roadPaint = Paint()..color = const Color(0xFF916F4A);
    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadWidth, roadLength),
      roadPaint,
    );

    // Lane markings
    final Paint dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    for (double y = 0; y < roadLength; y += 40) {
      canvas.drawLine(
        Offset(roadLeft + roadWidth * 0.5, y),
        Offset(roadLeft + roadWidth * 0.5, y + 20),
        dashPaint,
      );
    }

    // Stops
    final Paint circlePaint = Paint()..color = const Color(0xFFF03C18);
    final double stopSpacing = roadLength / 11;
    for (int i = 1; i <= 10; i++) {
      canvas.drawCircle(
        Offset(roadLeft + roadWidth * 0.5, i * stopSpacing),
        20,
        circlePaint,
      );
    }

    // Finish line
    final Paint linePaint1 = Paint()..color = Colors.white;
    final Paint linePaint2 = Paint()..color = Colors.black;
    for (double x = 0; x < roadWidth; x += 20) {
      canvas.drawRect(Rect.fromLTWH(roadLeft + x, 20, 10, 10), linePaint1);
      canvas.drawRect(Rect.fromLTWH(roadLeft + x + 10, 20, 10, 10), linePaint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlayerPainter extends CustomPainter {
  final Player player;
  final ui.Image image;
  final double scaleFactor;

  PlayerPainter({
    required this.player,
    required this.image,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = image.width.toDouble() * scaleFactor;
    final double height = image.height.toDouble() * scaleFactor;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        player.x - width / 2,
        player.y - height / 2,
        width,
        height,
      ),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
