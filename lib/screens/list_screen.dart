import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../widgets/todo_list.dart';
import '../widgets/completed_todo_list.dart';
import 'add_todo_screen.dart';
import 'calendar_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.todoService});

  final TodoService todoService;

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> with SingleTickerProviderStateMixin {
  // TodoList の状態を操作するためのキー
  Key _todoListKey = UniqueKey();
  Key _completedListKey = UniqueKey();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODOリスト'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'アクティブ', icon: Icon(Icons.list)),
            Tab(text: '完了済み', icon: Icon(Icons.check)),
            Tab(text: 'カレンダー', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodoList(
            key: _todoListKey,
            todoService: widget.todoService,
            onTodoCompleted: () {
              setState(() {
                _completedListKey = UniqueKey(); // 完了済みリストを更新
              });
            },
          ),
          CompletedTodoList(
            key: _completedListKey,
            todoService: widget.todoService,
            onTodoUncompleted: () {
              setState(() {
                _todoListKey = UniqueKey(); // アクティブリストを更新
              });
            },
          ),
          CalendarScreen(todoService: widget.todoService),
        ],
      ),
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
              _completedListKey = UniqueKey(); // 完了済みリストも再構築
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
