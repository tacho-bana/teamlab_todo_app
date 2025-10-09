import 'dart:convert'; // JSONデータの変換用
import 'package:shared_preferences/shared_preferences.dart'; // データ保存用
import '../models/todo.dart'; // 作成したTodoクラスを使用
import '../models/category.dart';
import 'category_service.dart';
import 'point_service.dart';

class TodoService {
  static const String _storageKey = 'todos'; // 保存時のキー名
  static const String _completedStorageKey = 'completed_todos'; // 完了済みTODOの保存キー
  final SharedPreferences _prefs; // データ保存の仕組み
  final CategoryService _categoryService; // カテゴリーサービス
  final PointService _pointService; // ポイントサービス

  TodoService(this._prefs) 
    : _categoryService = CategoryService(_prefs),
      _pointService = PointService(_prefs);

  // 保存されているTODOリストを読み込む（非同期処理）
  Future<List<Todo>> getTodos() async {
    return await _loadTodosFromKey(_storageKey);
  }

  // 完了済みTODOリストを読み込む（非同期処理）
  Future<List<Todo>> getCompletedTodos() async {
    return await _loadTodosFromKey(_completedStorageKey);
  }

  // TODOリストを保存する（非同期処理）
  Future<void> saveTodos(List<Todo> todos) async {
    await _saveTodosToKey(todos, _storageKey);
  }

  // 完了済みTODOリストを保存する（非同期処理）
  Future<void> saveCompletedTodos(List<Todo> todos) async {
    await _saveTodosToKey(todos, _completedStorageKey);
  }

  // TODOを完了済みに移動する
  Future<void> moveToCompleted(Todo todo) async {
    final completedTodos = await getCompletedTodos();
    final activeTodos = await getTodos();
    
    // 完了済みリストに追加（完了日を現在日時に設定）
    completedTodos.add(todo.copyWith(
      isCompleted: true,
      completedDate: DateTime.now(),
    ));
    await saveCompletedTodos(completedTodos);
    
    // アクティブリストから削除
    activeTodos.removeWhere((t) => t.id == todo.id);
    await saveTodos(activeTodos);
  }

  // TODOをアクティブに戻す
  Future<void> moveToActive(Todo todo) async {
    final completedTodos = await getCompletedTodos();
    final activeTodos = await getTodos();
    
    // アクティブリストに追加（完了日をクリア）
    activeTodos.add(todo.copyWith(
      isCompleted: false,
      completedDate: null,
    ));
    await saveTodos(activeTodos);
    
    // 完了済みリストから削除
    completedTodos.removeWhere((t) => t.id == todo.id);
    await saveCompletedTodos(completedTodos);
  }

  // 完了済みTODOを完全に削除する
  Future<void> deleteCompletedTodo(Todo todo) async {
    final completedTodos = await getCompletedTodos();
    completedTodos.removeWhere((t) => t.id == todo.id);
    await saveCompletedTodos(completedTodos);
  }

  // TODOを編集する
  Future<void> editTodo(Todo oldTodo, Todo newTodo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((t) => t.id == oldTodo.id);
    if (index != -1) {
      // 新しいTodoを元のIDで作成
      todos[index] = Todo(
        id: oldTodo.id,
        title: newTodo.title,
        detail: newTodo.detail,
        dueDate: newTodo.dueDate,
        isCompleted: newTodo.isCompleted,
        completedDate: newTodo.completedDate,
        category: newTodo.category,
      );
      await saveTodos(todos);
    }
  }

  // 共通の読み込みメソッド
  Future<List<Todo>> _loadTodosFromKey(String key) async {
    // 保存されているJSONデータを取得
    final String? todosJson = _prefs.getString(key);

    // データがない場合は空のリストを返す
    if (todosJson == null) return [];

    // JSON文字列をDartのオブジェクトに変換
    final List<dynamic> decoded = jsonDecode(todosJson);

    // 各データをTodoオブジェクトに変換してリストにする
    final List<Todo> todos = [];
    for (final json in decoded) {
      Category? category;
      if (json['categoryId'] != null) {
        category = await _categoryService.getCategoryById(json['categoryId']);
      }
      
      todos.add(Todo(
        id: json['id'],
        title: json['title'],
        detail: json['detail'] ?? '', // detailがない場合は空文字
        dueDate: DateTime.parse(
          json['dueDate'] ?? DateTime.now().toIso8601String(),
        ), // dueDateがない場合は現在日時
        isCompleted: json['isCompleted'],
        completedDate: json['completedDate'] != null 
            ? DateTime.parse(json['completedDate'])
            : null,
        category: category,
      ));
    }
    return todos;
  }

  // 共通の保存メソッド
  Future<void> _saveTodosToKey(List<Todo> todos, String key) async {
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
            'completedDate': todo.completedDate?.toIso8601String(), // 完了日も保存
            'categoryId': todo.category?.id, // カテゴリーのIDを保存
          },
        )
        .toList();

    // JSON文字列に変換
    final String encoded = jsonEncode(jsonData);

    // 変換した文字列を保存
    await _prefs.setString(key, encoded);
  }

  // 指定した日付に完了されたTODOの数を取得
  Future<int> getCompletedTodosCountForDate(DateTime date) async {
    final completedTodos = await getCompletedTodos();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return completedTodos.where((todo) {
      if (todo.completedDate == null) return false;
      final completedDateOnly = DateTime(
        todo.completedDate!.year,
        todo.completedDate!.month,
        todo.completedDate!.day,
      );
      return completedDateOnly.isAtSameMomentAs(targetDate);
    }).length;
  }

  // 完了済みTODOをポイントに変換して削除
  Future<int> convertCompletedTodoToPoints(Todo todo) async {
    final points = await _pointService.convertTodoToPoints();
    await deleteCompletedTodo(todo);
    return points;
  }

  // すべての完了済みTODOをポイントに変換して削除
  Future<int> convertAllCompletedTodosToPoints() async {
    final completedTodos = await getCompletedTodos();
    final totalPoints = completedTodos.length;
    
    for (int i = 0; i < totalPoints; i++) {
      await _pointService.convertTodoToPoints();
    }
    
    // すべての完了済みTODOを削除
    await saveCompletedTodos([]);
    
    return totalPoints;
  }

  // CategoryServiceを取得するメソッド
  CategoryService get categoryService => _categoryService;
  
  // PointServiceを取得するメソッド
  PointService get pointService => _pointService;
  
  // SharedPreferencesを取得するメソッド
  SharedPreferences get prefs => _prefs;
}
