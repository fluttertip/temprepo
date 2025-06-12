import 'package:bhagchal/widgets/two_player_game_board_ads.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;

  // late Timer turnTimer;
  Timer? _turnTimer;
  int turnTimeLeft = 60;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();

    // Initialize tigers at their default corners
    _gameState.nodes[0] = PieceType.tiger;
    _gameState.nodes[4] = PieceType.tiger;
    _gameState.nodes[20] = PieceType.tiger;
    _gameState.nodes[24] = PieceType.tiger;

    startOrResetTurnTimer(); // ⬅️ start the timer on game start
  }

  void _resetGame() {
    _turnTimer?.cancel();

    setState(() {
      _gameState = GameState();
      _gameState.nodes[0] = PieceType.tiger;
      _gameState.nodes[4] = PieceType.tiger;
      _gameState.nodes[20] = PieceType.tiger;
      _gameState.nodes[24] = PieceType.tiger;
      turnTimeLeft = 60;
    });
    startOrResetTurnTimer();
  }

  void _handleTap(int index) {
    bool moveMade = false;

    setState(() {
      if (_gameState.currentTurn == Turn.goat) {
        if (_gameState.goatsPlaced < 20) {
          moveMade = _gameState.placeGoat(index);
        } else {
          if (_gameState.selectedGoatIndex == null) {
            if (_gameState.nodes[index] == PieceType.goat) {
              _gameState.selectGoat(index);
            }
          } else {
            moveMade = _gameState.moveGoat(index);
            if (!moveMade) _gameState.resetSelection();
          }
        }
      } else {
        if (_gameState.nodes[index] == PieceType.tiger) {
          _gameState.selectTiger(index);
        } else if (_gameState.selectedTigerIndex != null) {
          moveMade = _gameState.moveTiger(index);
          if (!moveMade) _gameState.resetSelection();
        }
      }
    });

    if (moveMade) {
      startOrResetTurnTimer();
    }

    if (_gameState.isGameOver()) {
      _turnTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Game Over'),
            content: Text('${_gameState.winner} wins!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  _resetGame();
                },
                child: Text('Home'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetGame();
                },
                child: Text('Play Again'),
              ),
            ],
          ),
        );
      });
    }
  }

  void startOrResetTurnTimer() {
    _turnTimer?.cancel(); // cancel existing timer
    turnTimeLeft = 60;

    _turnTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (turnTimeLeft > 0) {
        setState(() {
          turnTimeLeft--;
        });
      } else {
        timer.cancel();
        _handleTurnTimeout();
      }
    });
  }

  void _handleTurnTimeout() {
    String loser = _gameState.currentTurn == Turn.goat ? 'Goat' : 'Tiger';
    String winner = _gameState.currentTurn == Turn.goat ? 'Tiger' : 'Goat';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time Out'),
        content: Text('$loser ran out of time.\n$winner wins!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              _resetGame();
            },
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Bhagchal Game'), centerTitle: true),
      body: Stack(
        fit: StackFit.expand,

        children: [
          // 🎨 Background Image
          Image.asset(
            'assets/images/openart-image_FakhGrIy_1748274245337_raw.jpg', // 🔁 change to your actual image path
            fit: BoxFit.cover,
          ),

          // 🧩 Foreground: Game UI
          Column(
            children: [
              // 👑 Turn indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100), // Shrunk from 30
                  const Text(
                    'Turn: ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    _gameState.currentTurn == Turn.goat
                        ? 'assets/images/goatthree.png'
                        : 'assets/images/tigerthree.png',
                    width: _gameState.currentTurn == Turn.goat ? 30 : 36,
                    height: _gameState.currentTurn == Turn.goat ? 30 : 36,
                  ),
                ],
              ),

              const SizedBox(height: 15), // Shrunk from 30
              // Placed and Eaten stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Row(
                        key: ValueKey(_gameState.goatsPlaced),
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Placed: ${_gameState.goatsPlaced}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          '',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (index) {
                            bool isFilled = index < _gameState.goatsCaptured;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled
                                    ? Colors.red
                                    : Colors.transparent,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.0,
                                ),
                              ),
                              child: isFilled
                                  ? ClipOval(
                                      child: Image.asset(
                                        'assets/images/goatthree.png',
                                        fit: BoxFit.cover,
                                        width: 20,
                                        height: 20,
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Reduced spacing
              // ⏳ Timer
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 60.0, end: turnTimeLeft.toDouble()),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: value / 60.0,
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            turnTimeLeft <= 10 ? Colors.red : Colors.blue,
                          ),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      Text(
                        '$turnTimeLeft s',
                        style: TextStyle(
                          fontSize: 13,
                          color: turnTimeLeft <= 10 ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 50), // Reduced spacing

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 20,
                ), // Add bottom padding
                child: TwoPlayerGameBoard(gameState: _gameState, onTap: _handleTap),
              ),
              // ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
