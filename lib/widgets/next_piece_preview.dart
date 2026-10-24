import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/next_piece_game.dart';
import '../models/game_state.dart';

/// 下一个方块的紧凑预览，尺寸由 [size] 控制。
class NextPiecePreview extends StatefulWidget {
  final GameState state;
  final double size;

  const NextPiecePreview({super.key, required this.state, this.size = 48});

  @override
  State<NextPiecePreview> createState() => _NextPiecePreviewState();
}

class _NextPiecePreviewState extends State<NextPiecePreview> {
  late final NextPieceGame _game = NextPieceGame(
    piece: widget.state.nextPiece,
  );

  @override
  void didUpdateWidget(covariant NextPiecePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.piece = widget.state.nextPiece;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.nextPiece == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GameWidget<NextPieceGame>(game: _game, autofocus: false),
    );
  }
}
