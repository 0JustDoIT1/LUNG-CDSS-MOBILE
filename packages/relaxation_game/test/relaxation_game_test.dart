import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relaxation_game/relaxation_game.dart';

void main() {
  MatchThreeController createController(int seed, {GameRecordStore? store}) {
    return MatchThreeController(
      random: Random(seed),
      animationDelay: Duration.zero,
      recordStore: store ?? MemoryGameRecordStore(),
    );
  }

  Future<bool> resolveFirstAvailableMove(
    MatchThreeController controller,
  ) async {
    for (var row = 0; row < MatchThreeController.boardSize; row++) {
      for (var column = 0; column < MatchThreeController.boardSize; column++) {
        final current = BoardPosition(row, column);
        if (column + 1 < MatchThreeController.boardSize &&
            await controller.trySwap(current, BoardPosition(row, column + 1))) {
          return true;
        }
        if (row + 1 < MatchThreeController.boardSize &&
            await controller.trySwap(current, BoardPosition(row + 1, column))) {
          return true;
        }
      }
    }
    return false;
  }

  group('MatchThreeController', () {
    test('creates a playable board without an immediate match', () async {
      final controller = createController(1);
      addTearDown(controller.dispose);
      await controller.recordsReady;

      expect(controller.board, hasLength(MatchThreeController.boardSize));
      expect(controller.boardHasMatches, isFalse);
      expect(controller.hasAvailableMove, isTrue);
      expect(controller.movesLeft, MatchThreeController.maxMoves);
    });

    test('rejects a non-adjacent swap', () async {
      final controller = createController(2);
      addTearDown(controller.dispose);
      await controller.recordsReady;

      final swapped = await controller.trySwap(
        const BoardPosition(0, 0),
        const BoardPosition(2, 2),
      );

      expect(swapped, isFalse);
      expect(controller.movesLeft, MatchThreeController.maxMoves);
      expect(controller.score, 0);
    });

    test('finds and resolves a valid move', () async {
      final controller = createController(3);
      addTearDown(controller.dispose);
      await controller.recordsReady;

      final resolved = await resolveFirstAvailableMove(controller);

      expect(resolved, isTrue);
      expect(controller.movesLeft, MatchThreeController.maxMoves - 1);
      expect(controller.score, greaterThan(0));
      expect(controller.boardHasMatches, isFalse);
    });

    test('new game resets progress but keeps records', () async {
      final controller = createController(4);
      addTearDown(controller.dispose);
      await controller.recordsReady;
      await resolveFirstAvailableMove(controller);
      final savedHighScore = controller.highScore;

      controller.newGame();

      expect(controller.score, 0);
      expect(controller.movesLeft, MatchThreeController.maxMoves);
      expect(controller.bestCombo, 0);
      expect(controller.highScore, savedHighScore);
    });

    test('loads the saved high score in a new controller', () async {
      final store = MemoryGameRecordStore();
      final first = createController(5, store: store);
      await first.recordsReady;
      await resolveFirstAvailableMove(first);
      final savedScore = first.highScore;
      first.dispose();

      final second = createController(6, store: store);
      addTearDown(second.dispose);
      await second.recordsReady;

      expect(savedScore, greaterThan(0));
      expect(second.highScore, savedScore);
      expect(second.highCombo, greaterThanOrEqualTo(1));
    });
  });
}
