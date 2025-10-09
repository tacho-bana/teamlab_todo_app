import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../widgets/todo_list.dart';
import '../widgets/completed_todo_list.dart';
import 'calendar_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.todoService, this.onSettingsChanged, this.onPointsChanged});

  final TodoService todoService;
  final VoidCallback? onSettingsChanged;
  final VoidCallback? onPointsChanged;

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  // TodoList の状態を操作するためのキー
  Key _todoListKey = UniqueKey();
  Key _completedListKey = UniqueKey();
  late TabController _tabController;
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await widget.todoService.pointService.getPoints();
    setState(() {
      _currentPoints = points;
    });
  }

  // TODO作成後のリスト更新用メソッド
  void refreshTodoLists() {
    setState(() {
      _todoListKey = UniqueKey(); // 新しいキーで TodoList を再構築
      _completedListKey = UniqueKey(); // 完了済みリストも再構築
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 透明にして親の背景を表示
      appBar: AppBar(
        toolbarHeight: 0, // タイトルエリアを非表示にして高さを調整
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TODO', icon: Icon(Icons.list)),
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
            onPointsChanged: () {
              _loadPoints(); // ポイント表示を更新
              widget.onPointsChanged?.call(); // 親にも通知
            },
          ),
          CalendarScreen(todoService: widget.todoService),
        ],
      ),
    );
  }
}
