import 'dart:async';

enum PieceType { none, goat, tiger }

enum Turn { goat, tiger }

enum GameStatus { waiting, inProgress, finished }

class MultiplayerGameState {
  // Game board state
  List<PieceType> nodes;
  Turn currentTurn;
  int? selectedTigerIndex;
  int? selectedGoatIndex;
  Set<int> highlightedNodes = {};
  int goatsPlaced = 0;
  int goatsCaptured = 0;
  final int totalGoats = 20;
  Turn? winner;

  // Multiplayer state
  final String playerId;
  final String roomId;
  final bool isHost;
  String? opponentId;
  bool isOpponentConnected = false;
  GameStatus status = GameStatus.waiting;

  // Adjacency map: index -> list of directly connected nodes
  final Map<int, List<int>> adjacentNodes = {
    0: [1, 5, 6],
    1: [0, 2, 6],
    2: [1, 3, 6, 7, 8],
    3: [2, 4, 8],
    4: [3, 9, 8],
    5: [0, 6, 10],
    6: [0, 1, 2, 5, 7, 10, 11, 12],
    7: [2, 6, 8, 12],
    8: [2, 3, 4, 7, 9, 12, 13, 14],
    9: [4, 8, 14],
    10: [5, 6, 11, 15, 16],
    11: [6, 10, 12, 16],
    12: [6, 7, 8, 11, 13, 16, 17, 18],
    13: [8, 12, 14, 18],
    14: [9, 8, 13, 18, 19],
    15: [10, 16, 20],
    16: [10, 11, 12, 15, 17, 20, 21, 22],
    17: [12, 16, 18, 22],
    18: [12, 13, 14, 17, 19, 22, 23, 24],
    19: [14, 18, 24],
    20: [15, 16, 21],
    21: [16, 20, 22],
    22: [16, 17, 18, 21, 23],
    23: [18, 22, 24],
    24: [18, 19, 23],
  };

  // Valid jump patterns for tiger captures
  final List<List<int>> validJumps = [
    // Horizontal jumps
    [0, 1, 2], [2, 1, 0],
    [1, 2, 3], [3, 2, 1],
    [2, 3, 4], [4, 3, 2],
    [5, 6, 7], [7, 6, 5],
    [6, 7, 8], [8, 7, 6],
    [7, 8, 9], [9, 8, 7],
    [10, 11, 12], [12, 11, 10],
    [11, 12, 13], [13, 12, 11],
    [12, 13, 14], [14, 13, 12],
    [15, 16, 17], [17, 16, 15],
    [16, 17, 18], [18, 17, 16],
    [17, 18, 19], [19, 18, 17],
    [20, 21, 22], [22, 21, 20],
    [21, 22, 23], [23, 22, 21],
    [22, 23, 24], [24, 23, 22],

    // Vertical jumps
    [0, 5, 10], [10, 5, 0],
    [5, 10, 15], [15, 10, 5],
    [10, 15, 20], [20, 15, 10],
    [1, 6, 11], [11, 6, 1],
    [6, 11, 16], [16, 11, 6],
    [11, 16, 21], [21, 16, 11],
    [2, 7, 12], [12, 7, 2],
    [7, 12, 17], [17, 12, 7],
    [12, 17, 22], [22, 17, 12],
    [3, 8, 13], [13, 8, 3],
    [8, 13, 18], [18, 13, 8],
    [13, 18, 23], [23, 18, 13],
    [4, 9, 14], [14, 9, 4],
    [9, 14, 19], [19, 14, 9],
    [14, 19, 24], [24, 19, 14],

    // Diagonal jumps (main diagonals)
    [0, 6, 12], [12, 6, 0],
    [6, 12, 18], [18, 12, 6],
    [12, 18, 24], [24, 18, 12],
    [4, 8, 12], [12, 8, 4],
    [8, 12, 16], [16, 12, 8],
    [12, 16, 20], [20, 16, 12],

    // Diagonal jumps (cross lines)
    [2, 6, 10], [10, 6, 2],
    [2, 8, 14], [14, 8, 2],
    [10, 16, 22], [22, 16, 10],
    [14, 18, 22], [22, 18, 14],
  ];

  MultiplayerGameState({
    required this.playerId,
    required this.roomId,
    required this.isHost,
  }) : nodes = List.generate(25, (_) => PieceType.none),
       currentTurn = Turn.goat {
    // Initialize tigers at their default corners
    nodes[0] = PieceType.tiger;
    nodes[4] = PieceType.tiger;
    nodes[20] = PieceType.tiger;
    nodes[24] = PieceType.tiger;
  }

  bool get allGoatsPlaced => goatsPlaced >= totalGoats;

  // Game state methods
  bool isReadyToStart() => status == GameStatus.waiting && isOpponentConnected;
  void startGame() => status = GameStatus.inProgress;
  void endGame() => status = GameStatus.finished;
  bool isGameInProgress() => status == GameStatus.inProgress;
  bool isGameOver() => status == GameStatus.finished;

  bool isMyTurn() {
    return (isHost && currentTurn == Turn.tiger) ||
        (!isHost && currentTurn == Turn.goat);
  }

  String getPlayerRole() => isHost ? 'Tiger' : 'Goat';
  String getOpponentRole() => isHost ? 'Goat' : 'Tiger';

  bool isPlayerWinner() {
    if (winner == null) return false;
    return (winner == Turn.tiger && isHost) || (winner == Turn.goat && !isHost);
  }

  bool isOpponentWinner() {
    if (winner == null) return false;
    return (winner == Turn.tiger && !isHost) || (winner == Turn.goat && isHost);
  }

  void updateGoatHighlights() {
    highlightedNodes.clear();
    if (!isMyTurn() || currentTurn != Turn.goat) return;

    if (!allGoatsPlaced) {
      // Highlight all empty nodes for placement
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i] == PieceType.none) {
          highlightedNodes.add(i);
        }
      }
    } else if (selectedGoatIndex != null) {
      // Highlight adjacent empty nodes for moving selected goat
      for (int adj in adjacentNodes[selectedGoatIndex!] ?? []) {
        if (nodes[adj] == PieceType.none) {
          highlightedNodes.add(adj);
        }
      }
    }
  }

  List<int> getLegalTigerMoves(int tigerIndex) {
    List<int> legalMoves = [];

    // Check adjacent move
    for (int adj in adjacentNodes[tigerIndex] ?? []) {
      if (nodes[adj] == PieceType.none) {
        legalMoves.add(adj);
      }
    }

    // Check jump (capture) move
    for (var jump in validJumps) {
      if (jump[0] == tigerIndex) {
        int over = jump[1];
        int to = jump[2];
        if (nodes[over] == PieceType.goat && nodes[to] == PieceType.none) {
          legalMoves.add(to);
        }
      }
    }

    return legalMoves;
  }

  List<int> getAllTigerIndexes() {
    List<int> tigerIndexes = [];
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i] == PieceType.tiger) {
        tigerIndexes.add(i);
      }
    }
    return tigerIndexes;
  }

  bool areAllTigersBlocked() {
    for (int index in getAllTigerIndexes()) {
      if (getLegalTigerMoves(index).isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  void checkGameOver() {
    if (goatsCaptured >= 5) {
      winner = Turn.tiger;
      endGame();
    } else if (areAllTigersBlocked()) {
      winner = Turn.goat;
      endGame();
    }
  }

  void changeTurn() {
    currentTurn = currentTurn == Turn.goat ? Turn.tiger : Turn.goat;
    highlightedNodes.clear();
    selectedTigerIndex = null;
    selectedGoatIndex = null;

    if (currentTurn == Turn.goat) {
      updateGoatHighlights();
    }

    checkGameOver();
  }

  bool placeGoat(int index) {
    if (!isMyTurn() || currentTurn != Turn.goat) return false;
    if (goatsPlaced >= totalGoats) return false;
    if (nodes[index] != PieceType.none) return false;

    nodes[index] = PieceType.goat;
    goatsPlaced++;
    changeTurn();
    return true;
  }

  bool selectGoat(int index) {
    if (!allGoatsPlaced) return false;
    if (!isMyTurn() || currentTurn != Turn.goat) return false;
    if (nodes[index] != PieceType.goat) return false;

    selectedGoatIndex = index;
    updateGoatHighlights();
    return true;
  }

  bool moveGoat(int index) {
    if (selectedGoatIndex == null) return false;
    if (!isMyTurn() || currentTurn != Turn.goat) return false;
    if (!highlightedNodes.contains(index)) return false;

    nodes[selectedGoatIndex!] = PieceType.none;
    nodes[index] = PieceType.goat;
    selectedGoatIndex = null;
    changeTurn();
    return true;
  }

  bool selectTiger(int index) {
    if (!isMyTurn() || currentTurn != Turn.tiger) return false;
    if (nodes[index] != PieceType.tiger) return false;

    selectedTigerIndex = index;
    highlightedNodes = Set.from(getLegalTigerMoves(index));
    return true;
  }

  bool moveTiger(int index) {
    if (selectedTigerIndex == null) return false;
    if (!isMyTurn() || currentTurn != Turn.tiger) return false;
    if (!highlightedNodes.contains(index)) return false;

    // Check if it's a capture move
    for (var jump in validJumps) {
      if (jump[0] == selectedTigerIndex && jump[2] == index) {
        int over = jump[1];
        if (nodes[over] == PieceType.goat) {
          nodes[over] = PieceType.none;
          goatsCaptured++;
          break;
        }
      }
    }

    nodes[selectedTigerIndex!] = PieceType.none;
    nodes[index] = PieceType.tiger;
    selectedTigerIndex = null;
    changeTurn();
    return true;
  }

  void resetSelection() {
    selectedTigerIndex = null;
    selectedGoatIndex = null;
    highlightedNodes.clear();
  }

  // Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'roomId': roomId,
      'isHost': isHost,
      'opponentId': opponentId,
      'isOpponentConnected': isOpponentConnected,
      'status': status.toString(),
      'currentTurn': currentTurn.toString(),
      'nodes': nodes.map((e) => e.toString()).toList(),
      'selectedTigerIndex': selectedTigerIndex,
      'selectedGoatIndex': selectedGoatIndex,
      'highlightedNodes': highlightedNodes.toList(),
      'goatsPlaced': goatsPlaced,
      'goatsCaptured': goatsCaptured,
      'winner': winner?.toString(),
    };
  }

  factory MultiplayerGameState.fromJson(
    Map<dynamic, dynamic> json,
    String currentPlayerId,
  ) {
    final state = MultiplayerGameState(
      playerId: currentPlayerId,
      roomId: json['roomId'] as String,
      isHost: json['isHost'] as bool,
    );

    state.opponentId = json['opponentId'] as String?;
    state.isOpponentConnected = json['isOpponentConnected'] as bool? ?? false;
    state.status = GameStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => GameStatus.waiting,
    );
    state.currentTurn = Turn.values.firstWhere(
      (e) => e.toString() == json['currentTurn'],
      orElse: () => Turn.tiger,
    );
    state.nodes = (json['nodes'] as List<dynamic>).map((e) {
      if (e == 'null') return PieceType.none;
      return PieceType.values.firstWhere(
        (type) => type.toString() == e,
        orElse: () => PieceType.none,
      );
    }).toList();
    state.selectedTigerIndex = json['selectedTigerIndex'] as int?;
    state.selectedGoatIndex = json['selectedGoatIndex'] as int?;
    state.highlightedNodes = Set<int>.from(
      json['highlightedNodes'] as List<dynamic>,
    );
    state.goatsPlaced = json['goatsPlaced'] as int? ?? 0;
    state.goatsCaptured = json['goatsCaptured'] as int? ?? 0;
    state.winner = json['winner'] != null
        ? Turn.values.firstWhere(
            (e) => e.toString() == json['winner'],
            orElse: () => Turn.tiger,
          )
        : null;

    return state;
  }

  factory MultiplayerGameState.empty() {
    return MultiplayerGameState(playerId: '', roomId: '', isHost: false);
  }

  void updateFromOpponentMove(MultiplayerGameState opponentState) {
    currentTurn = opponentState.currentTurn;
    nodes = opponentState.nodes;
    selectedTigerIndex = opponentState.selectedTigerIndex;
    selectedGoatIndex = opponentState.selectedGoatIndex;
    highlightedNodes = opponentState.highlightedNodes;
    goatsPlaced = opponentState.goatsPlaced;
    goatsCaptured = opponentState.goatsCaptured;
    winner = opponentState.winner;
    status = opponentState.status;
    isOpponentConnected = opponentState.isOpponentConnected;
  }
}
