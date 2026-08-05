import 'package:shared_preferences/shared_preferences.dart';

class GameRecords {
  const GameRecords({
    this.highScore = 0,
    this.highCombo = 0,
    this.gamesPlayed = 0,
    this.goalsReached = 0,
  });

  final int highScore;
  final int highCombo;
  final int gamesPlayed;
  final int goalsReached;
}

abstract interface class GameRecordStore {
  Future<GameRecords> load();

  Future<void> save(GameRecords records);
}

class SharedPreferencesGameRecordStore implements GameRecordStore {
  SharedPreferencesGameRecordStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _highScoreKey = 'relaxation_game.high_score';
  static const _highComboKey = 'relaxation_game.high_combo';
  static const _gamesPlayedKey = 'relaxation_game.games_played';
  static const _goalsReachedKey = 'relaxation_game.goals_reached';

  final SharedPreferencesAsync _preferences;

  @override
  Future<GameRecords> load() async {
    return GameRecords(
      highScore: await _preferences.getInt(_highScoreKey) ?? 0,
      highCombo: await _preferences.getInt(_highComboKey) ?? 0,
      gamesPlayed: await _preferences.getInt(_gamesPlayedKey) ?? 0,
      goalsReached: await _preferences.getInt(_goalsReachedKey) ?? 0,
    );
  }

  @override
  Future<void> save(GameRecords records) async {
    await Future.wait([
      _preferences.setInt(_highScoreKey, records.highScore),
      _preferences.setInt(_highComboKey, records.highCombo),
      _preferences.setInt(_gamesPlayedKey, records.gamesPlayed),
      _preferences.setInt(_goalsReachedKey, records.goalsReached),
    ]);
  }
}

class MemoryGameRecordStore implements GameRecordStore {
  MemoryGameRecordStore([this.records = const GameRecords()]);

  GameRecords records;

  @override
  Future<GameRecords> load() async => records;

  @override
  Future<void> save(GameRecords records) async {
    this.records = records;
  }
}
