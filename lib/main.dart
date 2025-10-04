import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 日本語などロケール情報を読み込む
import 'widgets/todo_card.dart'; // 追加: TodoCard をインポート
import 'models/todo.dart'; // Todo モデルをインポート

void main() async {
  // DateFormat で日本語表記を使えるようロケールを初期化
  await initializeDateFormatting('ja'); // 他言語の場合は"en"などに変更
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Todo App')),
        body: Center(
          child: TodoCard(
            todo: Todo(
              title: 'テストタイトル',
              detail: '説明文',
              dueDate: DateTime.now(),
            ),
            onToggle: () {},
          ),
        ),
      ),
    );
  }
}
