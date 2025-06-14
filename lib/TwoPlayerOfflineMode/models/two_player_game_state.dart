import 'dart:io';

enum PieceType { none, goat, tiger }

enum Turn { goat, tiger }

class GameState {
  List<PieceType> nodes;
  Turn currentTurn;
  int? selectedTigerIndex;
  int? selectedGoatIndex;
  int goatsPlaced;
  int goatsCaptured = 0;
  final int totalGoats = 20;
  String? winner; // 'Goat' or 'Tiger'
  Map<int, String> highlightedNodes =
      {}; // key = node index, value = 'tiger', 'goat_place', or 'goat_move'

  int get maxGoats => allGoatsPlaced ? totalGoats : totalGoats - goatsCaptured;

  GameState()
    : nodes = List.generate(25, (_) => PieceType.none),
      currentTurn = Turn.goat,
      selectedTigerIndex = null,
      selectedGoatIndex = null,
      goatsPlaced = 0;

  bool get allGoatsPlaced => goatsPlaced >= totalGoats;

  /// Adjacency map: index -> list of directly connected nodes
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

  void updateGoatHighlights() {
    highlightedNodes.clear();

    if (!isPlayersTurn(Turn.goat)) return;

    if (!allGoatsPlaced) {
      // Highlight all empty nodes for placement
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i] == PieceType.none) {
          // highlightedNodes.add(i);
          highlightedNodes[i] = 'goat_place';
        }
      }
    } else if (selectedGoatIndex != null) {
      // Highlight adjacent empty nodes for moving selected goat
      for (int adj in adjacentNodes[selectedGoatIndex!] ?? []) {
        if (nodes[adj] == PieceType.none) {
          // highlightedNodes.add(adj);
          highlightedNodes[adj] = 'goat_move';
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

  bool isGameOver() {
    if (goatsCaptured >= 5) {
      winner = 'Tiger';
      return true;
    }
    if (areAllTigersBlocked()) {
      winner = 'Goat';
      return true;
    }
    return false;
  }

  void changeTurn() {
    currentTurn = currentTurn == Turn.goat ? Turn.tiger : Turn.goat;
    highlightedNodes.clear();

    if (isGameOver()) {
      print('Game Over! Winner: $winner');
    } else {
      if (currentTurn == Turn.goat) {
        updateGoatHighlights();
      }
      print('Current turn: ${currentTurn == Turn.goat ? 'GOAT' : 'TIGER'}');
    }

    print('Turn changed: ${currentTurn == Turn.goat ? 'GOAT' : 'TIGER'}');
  }

  bool isPlayersTurn(Turn player) {
    return currentTurn == player;
  }

  bool placeGoat(int index) {
    print('Attempting to place GOAT at $index');
    if (!isPlayersTurn(Turn.goat)) {
      print('❌ Not GOAT\'s turn!');
      return false;
    }
    if (goatsPlaced >= totalGoats) {
      print('❌ All goats placed');
      return false;
    }
    if (nodes[index] != PieceType.none) {
      print('❌ Node $index is not empty');
      return false;
    }

    nodes[index] = PieceType.goat;
    goatsPlaced++;
    print('Placed GOAT at node $index (Total placed: $goatsPlaced)');
    changeTurn();

    return true;
  }

  bool selectGoat(int index) {
    print('Attempting to select GOAT at $index');
    if (!allGoatsPlaced) {
      print('❌ Cannot select goat before all goats are placed');
      return false;
    }
    if (!isPlayersTurn(Turn.goat)) {
      print('❌ Not GOAT\'s turn!');
      return false;
    }
    if (nodes[index] != PieceType.goat) {
      print('❌ No GOAT at node $index to select');
      return false;
    }
    selectedGoatIndex = index;
    updateGoatHighlights();
    print('Selected GOAT at $index');
    return true;
  }

  bool moveGoat(int toIndex) {
    print('Attempting to move GOAT to $toIndex');
    if (!isPlayersTurn(Turn.goat)) {
      print('❌ Not GOAT\'s turn!');
      return false;
    }
    if (selectedGoatIndex == null) {
      print('❌ No GOAT selected to move');
      return false;
    }
    if (nodes[toIndex] != PieceType.none) {
      print('❌ Target node $toIndex is not empty');
      return false;
    }
    if (!isAdjacent(selectedGoatIndex!, toIndex)) {
      print('❌ Target node $toIndex is not adjacent to selected GOAT');
      return false;
    }

    nodes[toIndex] = PieceType.goat;
    nodes[selectedGoatIndex!] = PieceType.none;
    print('Moved GOAT from ${selectedGoatIndex!} to $toIndex');
    selectedGoatIndex = null;
    changeTurn();

    return true;
  }

  bool selectTiger(int index) {
    print('Attempting to select TIGER at $index');
    if (!isPlayersTurn(Turn.tiger)) {
      print('❌ Not TIGER\'s turn!');
      return false;
    }
    if (nodes[index] != PieceType.tiger) {
      print('❌ No TIGER at node $index to select');
      return false;
    }
    selectedTigerIndex = index;
    highlightedNodes = {for (var i in getLegalTigerMoves(index)) i: 'tiger'};

    print('Selected TIGER at $index');
    return true;
  }

  bool moveTiger(int toIndex) {
    if (selectedTigerIndex == null) return false;

    int fromIndex = selectedTigerIndex!;
    if (adjacentNodes[fromIndex]?.contains(toIndex) == true &&
        nodes[toIndex] == PieceType.none) {
      nodes[toIndex] = PieceType.tiger;
      nodes[fromIndex] = PieceType.none;
      selectedTigerIndex = null;
      print('Moved TIGER from $fromIndex to $toIndex');

      changeTurn();

      return true;
    }

    for (var jump in validJumps) {
      if (jump[0] == fromIndex && jump[2] == toIndex) {
        int middle = jump[1];
        if (nodes[middle] == PieceType.goat &&
            nodes[toIndex] == PieceType.none) {
          nodes[toIndex] = PieceType.tiger;
          nodes[fromIndex] = PieceType.none;
          nodes[middle] = PieceType.none;
          goatsCaptured++;
          selectedTigerIndex = null;
          changeTurn();

          print(
            'Captured GOAT at $middle by moving TIGER from $fromIndex to $toIndex',
          );
          return true;
        }
      }
    }

    return false;
  }

  int? getCaptureGoatIndex(int from, int to) {
    for (var jump in validJumps) {
      if (jump[0] == from && jump[2] == to) {
        int over = jump[1];
        if (nodes[over] == PieceType.goat && nodes[to] == PieceType.none) {
          return over;
        }
      }
    }
    return null;
  }

  bool isAdjacent(int from, int to) {
    return adjacentNodes[from]?.contains(to) ?? false;
  }

  void resetSelection() {
    selectedTigerIndex = null;
    selectedGoatIndex = null;
    highlightedNodes.clear();

    print('🔄 Selections reset');
  }

  void printBoard() {
    print('📦 Current Board State:');
    for (int i = 0; i < 25; i++) {
      String symbol = nodes[i] == PieceType.none
          ? '.'
          : (nodes[i] == PieceType.goat ? 'G' : 'T');
      stdout.write('$symbol ');
      if ((i + 1) % 5 == 0) {
        print('');
      }
    }
  }
}
