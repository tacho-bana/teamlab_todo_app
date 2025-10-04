import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/list_screen.dart';
import 'services/todo_service.dart';

void main() async {
  // Flutter のプラグイン初期化。非同期処理を行う場合は必須
  WidgetsFlutterBinding.ensureInitialized();

  // DateFormat で日本語表記を使えるようロケールを初期化
  await initializeDateFormatting('ja'); // 他言語の場合は"en"などに変更

  // ① SharedPreferences を初期化（端末に小さなキー／バリューで保存できる）
  final prefs = await SharedPreferences.getInstance();

  // ② SharedPreferences を使って TodoService を生成（保存・読み込みの窓口）
  final todoService = TodoService(prefs);

  // ③ TodoService をアプリ全体へ渡す
  runApp(MyApp(todoService: todoService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.todoService});

  // アプリ全体で共有する TodoService
  final TodoService todoService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ListScreen にtodoServiceを引数としてわたす
      home: ListScreen(todoService: todoService),
    );
  }
}
