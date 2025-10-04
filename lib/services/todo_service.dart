import 'dart:convert'; // JSONデータの変換用
import 'package:shared_preferences/shared_preferences.dart'; // データ保存用
import '../models/todo.dart'; // 作成したTodoクラスを使用

class TodoService {
  static const String _storageKey = 'todos'; // 保存時のキー名
  final SharedPreferences _prefs; // データ保存の仕組み

  TodoService(this._prefs);

  // 保存されているTODOリストを読み込む（非同期処理）
  Future<List<Todo>> getTodos() async {
    // 保存されているJSONデータを取得
    final String? todosJson = _prefs.getString(_storageKey);

    // データがない場合は空のリストを返す
    if (todosJson == null) return [];

    // JSON文字列をDartのオブジェクトに変換
    final List<dynamic> decoded = jsonDecode(todosJson);

    // 各データをTodoオブジェクトに変換してリストにする
    return decoded
        .map(
          (json) => Todo(
            id: json['id'],
            title: json['title'],
            detail: json['detail'] ?? '', // detailがない場合は空文字
            dueDate: DateTime.parse(
              json['dueDate'] ?? DateTime.now().toIso8601String(),
            ), // dueDateがない場合は現在日時
            isCompleted: json['isCompleted'],
          ),
        )
        .toList();
  }

  // TODOリストを保存する（非同期処理）
  Future<void> saveTodos(List<Todo> todos) async {
    // TodoオブジェクトをJSONに変換できる形に変換
    final List<Map<String, dynamic>> jsonData = todos
        .map(
          (todo) => {
            'id': todo.id,
            'title': todo.title,
            'detail': todo.detail,
            'dueDate': todo.dueDate
                .toIso8601String(), // DateTimeをISO8601形式の文字列に変換
            'isCompleted': todo.isCompleted,
          },
        )
        .toList();

    // JSON文字列に変換
    final String encoded = jsonEncode(jsonData);

    // 変換した文字列を保存
    await _prefs.setString(_storageKey, encoded);
  }
}
