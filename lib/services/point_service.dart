import 'package:shared_preferences/shared_preferences.dart';

class PointService {
  static const String _storageKey = 'user_points';
  final SharedPreferences _prefs;

  PointService(this._prefs);

  // 現在のポイントを取得
  Future<int> getPoints() async {
    return _prefs.getInt(_storageKey) ?? 0;
  }

  // ポイントを追加
  Future<void> addPoints(int points) async {
    final currentPoints = await getPoints();
    await _prefs.setInt(_storageKey, currentPoints + points);
  }

  // ポイントを消費
  Future<bool> spendPoints(int points) async {
    final currentPoints = await getPoints();
    if (currentPoints >= points) {
      await _prefs.setInt(_storageKey, currentPoints - points);
      return true;
    }
    return false;
  }

  // ポイントをリセット
  Future<void> resetPoints() async {
    await _prefs.setInt(_storageKey, 0);
  }

  // 完了したTODOをポイントに変換
  Future<int> convertTodoToPoints() async {
    const pointsPerTodo = 1; // 1TODO = 1ポイント
    await addPoints(pointsPerTodo);
    return pointsPerTodo;
  }
}