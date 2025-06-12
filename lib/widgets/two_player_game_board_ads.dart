import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';

class TwoPlayerGameBoard extends StatelessWidget {
  final GameState gameState;
  final void Function(int nodeIndex) onTap;

  const TwoPlayerGameBoard({super.key, required this.gameState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Or any value you prefer
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final padding = 24.0;
              final drawSize = Size(
                size.width - padding * 2,
                size.height - padding * 2,
              );

              // Sizes for node circles and pieces
              const double nodeCircleDiameter = 32.0;
              // const double goatSize = 32.0;
              const double goatBaseSize = 32.0;
              const double goatSelectedSize = 38.0;

              const double tigerBaseSize = 54.0;
              const double tigerSelectedSize = 60.0;

              return Stack(
                children: [
                  // Draw board background lines
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: CustomPaint(painter: _BoardPainter()),
                    ),
                  ),

                  // Draw each node (circle + piece)
                  ...List.generate(boardNodes.length, (index) {
                    final node = boardNodes[index];

                    // Calculate center position for this node
                    final centerX = padding + node.dx / 4 * drawSize.width;
                    final centerY = padding + node.dy / 4 * drawSize.height;

                    final piece = gameState.nodes[index];
                    final highlightType = gameState.highlightedNodes[index];

                    // Background color logic for node circle
                    Color backgroundColor;

                    switch (highlightType) {
                      case 'tiger':
                        backgroundColor = Colors.orange.withOpacity(0.6);
                        break;
                      case 'goat_place':
                        backgroundColor = Colors.blue.withOpacity(0.3);
                        break;
                      case 'goat_move':
                        backgroundColor = Colors.blue.withOpacity(0.6);
                        break;
                      default:
                        backgroundColor = piece == PieceType.none
                            ? Colors.white.withOpacity(0.1)
                            : piece == PieceType.goat
                            ? Colors.brown
                            : Colors.orange;
                    }

                    // Determine piece size and offset for positioning
                    double pieceSize;
                    if (piece == PieceType.tiger) {
                      pieceSize = (gameState.selectedTigerIndex == index)
                          ? tigerSelectedSize
                          : tigerBaseSize;
                    } else if (piece == PieceType.goat) {
                      // pieceSize = goatSize;
                      pieceSize = (gameState.selectedGoatIndex == index)
                          ? goatSelectedSize
                          : goatBaseSize;
                    } else {
                      pieceSize = nodeCircleDiameter;
                    }
                    final pieceOffset = pieceSize / 2;

                    return Positioned(
                      // Position by center minus half of piece size for perfect center alignment
                      left: centerX - pieceOffset,
                      top: centerY - pieceOffset,
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        child: piece == PieceType.none
                            ? Container(
                                width: nodeCircleDiameter,
                                height: nodeCircleDiameter,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: backgroundColor,
                                  border: Border.all(color: Colors.grey),
                                ),
                              )
                            : piece == PieceType.tiger
                            ? AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: pieceSize,
                                height: pieceSize,
                                child: Image.asset(
                                  'assets/images/tigerthree.png',
                                  fit: BoxFit.contain,
                                ),
                              )
                            : AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: pieceSize,
                                height: pieceSize,
                                child: Image.asset(
                                  'assets/images/goatthree.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5;

    Offset getOffset(int index) {
      final point = boardNodes[index];
      return Offset(point.dx / 4 * size.width, point.dy / 4 * size.height);
    }

    // Horizontal lines (5 rows)
    for (int row = 0; row < 5; row++) {
      canvas.drawLine(getOffset(row * 5), getOffset(row * 5 + 4), paint);
    }

    // Vertical lines (5 columns)
    for (int col = 0; col < 5; col++) {
      canvas.drawLine(getOffset(col), getOffset(20 + col), paint);
    }

    // Major diagonals
    canvas.drawLine(getOffset(0), getOffset(24), paint);
    canvas.drawLine(getOffset(20), getOffset(4), paint);

    // Smaller diagonals
    canvas.drawLine(getOffset(2), getOffset(6), paint);
    canvas.drawLine(getOffset(6), getOffset(10), paint);
    canvas.drawLine(getOffset(2), getOffset(8), paint);
    canvas.drawLine(getOffset(8), getOffset(14), paint);
    canvas.drawLine(getOffset(10), getOffset(16), paint);
    canvas.drawLine(getOffset(16), getOffset(22), paint);
    canvas.drawLine(getOffset(14), getOffset(18), paint);
    canvas.drawLine(getOffset(18), getOffset(22), paint);

    // Draw node circles consistently sized and positioned by center points
    const double nodeCircleRadius = 16;

    for (final node in boardNodes) {
      final center = Offset(
        node.dx / 4 * size.width,
        node.dy / 4 * size.height,
      );
      canvas.drawCircle(
        center,
        nodeCircleRadius,
        paint..color = const Color.fromARGB(144, 0, 0, 0),
      );
      paint.color = Colors.black;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
