import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bhagchal/MultiplayerMode/models/multiplayer_game_state.dart';
import 'package:bhagchal/MultiplayerMode/widgets/multiplayer_game_board.dart';
import 'package:bhagchal/MultiplayerMode/utils/firebase_service.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String playerId;
  final String roomId;
  final bool isHost;

  const MultiplayerGameScreen({
    super.key,
    required this.playerId,
    required this.roomId,
    required this.isHost,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late MultiplayerGameState _gameState;
  final _firebaseService = FirebaseService();
  Timer? _turnTimer;
  int turnTimeLeft = 60;
  bool _isOpponentConnected = false;
  StreamSubscription? _gameStateSubscription;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _gameState = MultiplayerGameState(
      playerId: widget.playerId,
      isHost: widget.isHost,
      roomId: widget.roomId,
    );

    // Initialize tigers at their default corners
    _gameState.nodes[0] = PieceType.tiger;
    _gameState.nodes[4] = PieceType.tiger;
    _gameState.nodes[20] = PieceType.tiger;
    _gameState.nodes[24] = PieceType.tiger;

    _initializeGameConnection();
  }

  void _initializeGameConnection() async {
    try {
      // Watch game state changes
      _gameStateSubscription = _firebaseService
          .watchGameState(widget.roomId, widget.playerId)
          .listen((state) {
            setState(() {
              _gameState.updateFromOpponentMove(state);
              if (_gameState.isGameOver()) {
                _turnTimer?.cancel();
                _showGameOverDialog();
              }
            });
          });

      // Update player status
      await _firebaseService.updatePlayerStatus(
        widget.roomId,
        widget.playerId,
        true,
      );

      // Watch opponent connection status
      _connectionSubscription = _firebaseService
          .watchGameState(widget.roomId, widget.playerId)
          .listen((state) {
            setState(() {
              _isOpponentConnected = state.isOpponentConnected;
              if (_isOpponentConnected && _gameState.isReadyToStart()) {
                _gameState.startGame();
              }
            });
          });
    } catch (e) {
      print('Failed to initialize game connection: $e');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Connection Error'),
            content: const Text(
              'Failed to connect to the game server. Please try again later.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleTap(int index) {
    if (!_gameState.isMyTurn() ||
        !_isOpponentConnected ||
        !_gameState.isGameInProgress())
      return;

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
      _firebaseService.updateGameState(widget.roomId, _gameState);
    }

    if (_gameState.isGameOver()) {
      _turnTimer?.cancel();
      _gameState.endGame();
      _firebaseService.updateGameState(widget.roomId, _gameState);
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Game Over'),
          content: Text(
            _gameState.isPlayerWinner()
                ? 'You won!'
                : _gameState.isOpponentWinner()
                ? 'Opponent won!'
                : 'Game ended in a draw!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
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
    });
  }

  void _resetGame() {
    _turnTimer?.cancel();

    setState(() {
      _gameState = MultiplayerGameState(
        playerId: widget.playerId,
        isHost: widget.isHost,
        roomId: widget.roomId,
      );
      _gameState.nodes[0] = PieceType.tiger;
      _gameState.nodes[4] = PieceType.tiger;
      _gameState.nodes[20] = PieceType.tiger;
      _gameState.nodes[24] = PieceType.tiger;
      turnTimeLeft = 60;
    });
    startOrResetTurnTimer();
    _firebaseService.updateGameState(widget.roomId, _gameState);
  }

  void startOrResetTurnTimer() {
    _turnTimer?.cancel();
    turnTimeLeft = 60;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/openart-image_FakhGrIy_1748274245337_raw.jpg',
            fit: BoxFit.cover,
          ),

          // Game UI
          Column(
            children: [
              // Connection status
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOpponentConnected ? Icons.link : Icons.link_off,
                      color: _isOpponentConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOpponentConnected
                          ? 'Opponent Connected'
                          : 'Waiting for opponent...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Game status
              if (!_gameState.isGameInProgress())
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    _gameState.isReadyToStart()
                        ? 'Game starting...'
                        : 'Waiting for opponent to join...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

              // Turn indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
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

              const SizedBox(height: 15),

              // Game stats
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
                          'Captured: ',
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
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game board
              Expanded(
                child: Center(
                  child: MultiplayerGameBoard(
                    nodes: _gameState.nodes,
                    onTap: _handleTap,
                    highlightedNodes: _gameState.highlightedNodes,
                    isMyTurn: _gameState.isMyTurn(),
                    playerRole: _gameState.getPlayerRole(),
                  ),
                ),
              ),

              // Timer
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Time Left: $turnTimeLeft',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _gameStateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _firebaseService.updatePlayerStatus(widget.roomId, widget.playerId, false);
    super.dispose();
  }
}
