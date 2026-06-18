import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'next_piece_painter.dart';

class NextPiecePreview extends StatelessWidget {
  final GameState state;
  const NextPiecePreview({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.nextPiece == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('下一个', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: NextPiecePainter(piece: state.nextPiece!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
