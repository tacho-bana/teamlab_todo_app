import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _backgroundKey = 'selected_background';
  static const String _fontKey = 'selected_font';
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // 選択中の背景を取得
  Future<String> getSelectedBackground() async {
    return _prefs.getString(_backgroundKey) ?? 'default';
  }

  // 背景を設定
  Future<void> setSelectedBackground(String backgroundId) async {
    await _prefs.setString(_backgroundKey, backgroundId);
  }

  // 選択中のフォントを取得
  Future<String> getSelectedFont() async {
    return _prefs.getString(_fontKey) ?? 'Yomogi';
  }

  // フォントを設定
  Future<void> setSelectedFont(String fontId) async {
    await _prefs.setString(_fontKey, fontId);
  }

  // 設定をリセット
  Future<void> resetSettings() async {
    await _prefs.remove(_backgroundKey);
    await _prefs.remove(_fontKey);
  }
}