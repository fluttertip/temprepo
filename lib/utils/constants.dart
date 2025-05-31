import 'package:flutter/material.dart';

final List<Offset> boardNodes = List.generate(
  5,
  (y) => List.generate(5, (x) => Offset(x.toDouble(), y.toDouble())),
).expand((row) => row).toList();

final List<List<int>> boardEdges = [];

void generateEdges() {
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      int i = y * 5 + x;

      // Right
      if (x < 4) boardEdges.add([i, i + 1]);

      // Down
      if (y < 4) boardEdges.add([i, i + 5]);

      // Diagonal down-right
      if (x < 4 && y < 4) boardEdges.add([i, i + 6]);

      // Diagonal down-left
      if (x > 0 && y < 4) boardEdges.add([i, i + 4]);
    }
  }
}
