import 'package:flutter/material.dart';
import 'package:bhagchal/MultiplayerMode/models/multiplayer_game_state.dart';

class MultiplayerGameBoard extends StatelessWidget {
  final List<PieceType> nodes;
  final Function(int) onTap;
  final Set<int> highlightedNodes;
  final bool isMyTurn;
  final String playerRole;

  const MultiplayerGameBoard({
    super.key,
    required this.nodes,
    required this.onTap,
    required this.highlightedNodes,
    required this.isMyTurn,
    required this.playerRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid lines
          CustomPaint(painter: BoardPainter(), size: const Size(300, 300)),

          // Game pieces and nodes
          ...List.generate(25, (index) {
            final row = index ~/ 5;
            final col = index % 5;
            final x = col * 75.0;
            final y = row * 75.0;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlightedNodes.contains(index)
                        ? Colors.green.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Center(child: _buildPiece(nodes[index])),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPiece(PieceType? type) {
    if (type == null || type == PieceType.none) return const SizedBox();

    return Image.asset(
      type == PieceType.tiger
          ? 'assets/images/tigerthree.png'
          : 'assets/images/goatthree.png',
      width: type == PieceType.tiger ? 36 : 30,
      height: type == PieceType.tiger ? 36 : 30,
    );
  }
}

class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (int i = 0; i < 5; i++) {
      // Horizontal lines
      canvas.drawLine(Offset(0, i * 75.0), Offset(size.width, i * 75.0), paint);

      // Vertical lines
      canvas.drawLine(
        Offset(i * 75.0, 0),
        Offset(i * 75.0, size.height),
        paint,
      );
    }

    // Draw diagonal lines
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Draw center cross
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
