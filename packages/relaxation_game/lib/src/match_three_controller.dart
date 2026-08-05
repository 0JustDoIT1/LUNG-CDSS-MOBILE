import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_record_store.dart';

enum AnimalTile { puppy, kitten, bunny, bear, panda, fox }

extension AnimalTilePresentation on AnimalTile {
  String get emoji => switch (this) {
    AnimalTile.puppy => '🐶',
    AnimalTile.kitten => '🐱',
    AnimalTile.bunny => '🐰',
    AnimalTile.bear => '🐻',
    AnimalTile.panda => '🐼',
    AnimalTile.fox => '🦊',
  };
}

@immutable
class BoardPosition {
  const BoardPosition(this.row, this.column);

  final int row;
  final int column;

  bool isAdjacentTo(BoardPosition other) {
    return (row - other.row).abs() + (column - other.column).abs() == 1;
  }

  @override
  bool operator ==(Object other) {
    return other is BoardPosition && row == other.row && column == other.column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class MatchThreeController extends ChangeNotifier {
  MatchThreeController({
    Random? random,
    this.animationDelay = const Duration(milliseconds: 150),
    GameRecordStore? recordStore,
  }) : _random = random ?? Random(),
       _recordStore = recordStore ?? SharedPreferencesGameRecordStore() {
    _createBoard();
    recordsReady = _loadRecords();
  }

  static const int boardSize = 8;
  static const int maxMoves = 30;
  static const int goalScore = 2500;

  final Random _random;
  final Duration animationDelay;
  final GameRecordStore _recordStore;
  late List<List<AnimalTile?>> _board;
  late final Future<void> recordsReady;

  int score = 0;
  int movesLeft = maxMoves;
  int bestCombo = 0;
  int lastCombo = 0;
  int lastScoreGain = 0;
  int feedbackSerial = 0;
  int highScore = 0;
  int highCombo = 0;
  int gamesPlayed = 0;
  int goalsReached = 0;
  bool isResolving = false;
  bool isLoadingRecords = true;
  bool _gameResultSaved = false;
  BoardPosition? selected;
  Set<BoardPosition> clearingPositions = const {};

  bool get isGameOver => movesLeft <= 0 && !isResolving;
  double get goalProgress => min(1, score / goalScore);
  bool get reachedGoal => score >= goalScore;

  List<List<AnimalTile?>> get board =>
      _board.map((row) => List<AnimalTile?>.from(row)).toList(growable: false);

  AnimalTile? tileAt(BoardPosition position) {
    return _board[position.row][position.column];
  }

  Future<void> selectTile(BoardPosition position) async {
    if (isGameOver || isResolving) return;

    final previous = selected;
    if (previous == null) {
      selected = position;
      notifyListeners();
      return;
    }
    if (previous == position) {
      selected = null;
      notifyListeners();
      return;
    }
    if (!previous.isAdjacentTo(position)) {
      selected = position;
      notifyListeners();
      return;
    }

    selected = null;
    await trySwap(previous, position);
  }

  Future<bool> trySwap(BoardPosition first, BoardPosition second) async {
    if (isGameOver || isResolving || !first.isAdjacentTo(second)) return false;

    isResolving = true;
    lastScoreGain = 0;
    lastCombo = 0;
    _swap(first, second);
    notifyListeners();
    await _wait();

    var matches = _findMatches();
    if (matches.isEmpty) {
      _swap(first, second);
      isResolving = false;
      notifyListeners();
      return false;
    }

    movesLeft -= 1;
    var chain = 1;
    while (matches.isNotEmpty && chain <= 50) {
      final gain = matches.length * 10 * chain;
      score += gain;
      lastScoreGain = gain;
      lastCombo = chain;
      bestCombo = max(bestCombo, chain);
      feedbackSerial += 1;
      clearingPositions = Set.unmodifiable(matches);
      notifyListeners();
      await _wait();

      _remove(matches);
      clearingPositions = const {};
      notifyListeners();
      await _wait(factor: 0.55);

      _collapseAndRefill();
      notifyListeners();
      await _wait();

      chain += 1;
      matches = _findMatches();
    }

    if (movesLeft > 0 && !_hasAvailableMove()) {
      _createBoard(keepProgress: true);
    }
    await _updateRecords(gameCompleted: movesLeft <= 0);
    isResolving = false;
    notifyListeners();
    return true;
  }

  void shuffle() {
    if (isGameOver || isResolving) return;
    selected = null;
    _createBoard(keepProgress: true);
    notifyListeners();
  }

  void newGame() {
    score = 0;
    movesLeft = maxMoves;
    bestCombo = 0;
    lastCombo = 0;
    lastScoreGain = 0;
    feedbackSerial = 0;
    isResolving = false;
    _gameResultSaved = false;
    clearingPositions = const {};
    selected = null;
    _createBoard();
    notifyListeners();
  }

  @visibleForTesting
  bool get boardHasMatches => _findMatches().isNotEmpty;

  @visibleForTesting
  bool get hasAvailableMove => _hasAvailableMove();

  Future<void> _loadRecords() async {
    try {
      final records = await _recordStore.load();
      highScore = max(highScore, records.highScore);
      highCombo = max(highCombo, records.highCombo);
      gamesPlayed = max(gamesPlayed, records.gamesPlayed);
      goalsReached = max(goalsReached, records.goalsReached);
    } catch (_) {
      // 저장소를 사용할 수 없어도 게임 플레이는 계속할 수 있어야 한다.
    } finally {
      isLoadingRecords = false;
      notifyListeners();
    }
  }

  Future<void> _updateRecords({required bool gameCompleted}) async {
    await recordsReady;
    var changed = false;
    if (score > highScore) {
      highScore = score;
      changed = true;
    }
    if (bestCombo > highCombo) {
      highCombo = bestCombo;
      changed = true;
    }
    if (gameCompleted && !_gameResultSaved) {
      gamesPlayed += 1;
      if (reachedGoal) goalsReached += 1;
      _gameResultSaved = true;
      changed = true;
    }
    if (!changed) return;
    try {
      await _recordStore.save(
        GameRecords(
          highScore: highScore,
          highCombo: highCombo,
          gamesPlayed: gamesPlayed,
          goalsReached: goalsReached,
        ),
      );
    } catch (_) {
      // 저장 실패가 매칭 처리나 UI를 중단시키지 않도록 한다.
    }
  }

  Future<void> _wait({double factor = 1}) async {
    if (animationDelay == Duration.zero) return;
    await Future<void>.delayed(animationDelay * factor);
  }

  void _createBoard({bool keepProgress = false}) {
    do {
      final candidate = <List<AnimalTile?>>[];
      for (var row = 0; row < boardSize; row++) {
        final currentRow = <AnimalTile?>[];
        for (var column = 0; column < boardSize; column++) {
          final blocked = <AnimalTile>{};
          if (column >= 2 && currentRow[column - 1] == currentRow[column - 2]) {
            blocked.add(currentRow[column - 1]!);
          }
          if (row >= 2 &&
              candidate[row - 1][column] == candidate[row - 2][column]) {
            blocked.add(candidate[row - 1][column]!);
          }
          final choices = AnimalTile.values
              .where((tile) => !blocked.contains(tile))
              .toList(growable: false);
          currentRow.add(choices[_random.nextInt(choices.length)]);
        }
        candidate.add(currentRow);
      }
      _board = candidate;
    } while (!_hasAvailableMove());

    if (!keepProgress) selected = null;
  }

  void _swap(BoardPosition first, BoardPosition second) {
    final value = _board[first.row][first.column];
    _board[first.row][first.column] = _board[second.row][second.column];
    _board[second.row][second.column] = value;
  }

  Set<BoardPosition> _findMatches() {
    final matches = <BoardPosition>{};
    for (var row = 0; row < boardSize; row++) {
      var runStart = 0;
      for (var column = 1; column <= boardSize; column++) {
        final continues =
            column < boardSize &&
            _board[row][column] != null &&
            _board[row][column] == _board[row][runStart];
        if (continues) continue;
        if (_board[row][runStart] != null && column - runStart >= 3) {
          for (
            var matchColumn = runStart;
            matchColumn < column;
            matchColumn++
          ) {
            matches.add(BoardPosition(row, matchColumn));
          }
        }
        runStart = column;
      }
    }
    for (var column = 0; column < boardSize; column++) {
      var runStart = 0;
      for (var row = 1; row <= boardSize; row++) {
        final continues =
            row < boardSize &&
            _board[row][column] != null &&
            _board[row][column] == _board[runStart][column];
        if (continues) continue;
        if (_board[runStart][column] != null && row - runStart >= 3) {
          for (var matchRow = runStart; matchRow < row; matchRow++) {
            matches.add(BoardPosition(matchRow, column));
          }
        }
        runStart = row;
      }
    }
    return matches;
  }

  void _remove(Set<BoardPosition> matches) {
    for (final position in matches) {
      _board[position.row][position.column] = null;
    }
  }

  void _collapseAndRefill() {
    for (var column = 0; column < boardSize; column++) {
      final remaining = <AnimalTile>[];
      for (var row = boardSize - 1; row >= 0; row--) {
        final tile = _board[row][column];
        if (tile != null) remaining.add(tile);
      }
      var index = 0;
      for (var row = boardSize - 1; row >= 0; row--) {
        _board[row][column] = index < remaining.length
            ? remaining[index++]
            : AnimalTile.values[_random.nextInt(AnimalTile.values.length)];
      }
    }
  }

  bool _hasAvailableMove() {
    for (var row = 0; row < boardSize; row++) {
      for (var column = 0; column < boardSize; column++) {
        final current = BoardPosition(row, column);
        for (final next in [
          if (column + 1 < boardSize) BoardPosition(row, column + 1),
          if (row + 1 < boardSize) BoardPosition(row + 1, column),
        ]) {
          _swap(current, next);
          final createsMatch = _findMatches().isNotEmpty;
          _swap(current, next);
          if (createsMatch) return true;
        }
      }
    }
    return false;
  }
}
