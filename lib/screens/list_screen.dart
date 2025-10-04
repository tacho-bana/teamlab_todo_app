import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../widgets/todo_list.dart';
import 'add_todo_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.todoService});

  final TodoService todoService;

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  // TodoList の状態を操作するためのキー
  Key _todoListKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TODOリスト')),
      body: TodoList(
        key: _todoListKey,
        todoService: widget.todoService,
      ), // TodoList ウィジェットを配置
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 画面遷移し、戻ってきたら結果（新規 Todo）を受け取る
          final updated = await Navigator.push(
            // Todoに追加があったらtrueを返す
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoScreen(
                todoService: widget.todoService, // 引数としてtodoServiceを渡す
              ),
            ),
          );

          // 追加があったら再描画（TodoList を再取得）
          if (updated == true) {
            setState(() {
              _todoListKey = UniqueKey(); // 新しいキーで TodoList を再構築
            });
          }
        },
        backgroundColor: const Color.fromARGB(
          255,
          0,
          0,
          255,
        ), // ボタンの背景色（RGBAでも指定できます）
        foregroundColor: Colors.white, // アイコンやテキストなど、ボタン内の要素の色
        child: const Icon(Icons.add), // Flutter標準の「＋」アイコン
      ),
    );
  }
}
