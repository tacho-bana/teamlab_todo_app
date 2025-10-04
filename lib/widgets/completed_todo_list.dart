import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_card.dart';

class CompletedTodoList extends StatefulWidget {
  const CompletedTodoList({super.key, required this.todoService, this.onTodoUncompleted});

  final TodoService todoService;
  final VoidCallback? onTodoUncompleted; // アクティブに戻した時のコールバック

  @override
  State<CompletedTodoList> createState() => CompletedTodoListState();
}

class CompletedTodoListState extends State<CompletedTodoList> {
  List<Todo> _completedTodos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedTodos();
  }

  Future<void> _loadCompletedTodos() async {
    final todos = await widget.todoService.getCompletedTodos();
    // 期限順にソート（完了日順でもよいが、期限順にする）
    todos.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    setState(() {
      _completedTodos = todos;
      _isLoading = false;
    });
  }

  // チェックを外してアクティブに戻す
  Future<void> _moveToActive(Todo todo) async {
    await widget.todoService.moveToActive(todo);
    _loadCompletedTodos(); // リストを再読み込み
    widget.onTodoUncompleted?.call(); // 親画面にアクティブ復帰を通知
  }

  // 完了済みTODOを削除する
  Future<void> _deleteTodo(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TODO削除'),
        content: Text('「${todo.title}」を完全に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.todoService.deleteCompletedTodo(todo);
      _loadCompletedTodos(); // リストを再読み込み
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedTodos.isEmpty) {
      return const Center(
        child: Text(
          '完了したTODOはありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _completedTodos.length,
      itemBuilder: (context, index) {
        final todo = _completedTodos[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Opacity(
            opacity: 0.7, // 完了済みは少し薄く表示
            child: TodoCard(
              todo: todo,
              onToggle: () => _moveToActive(todo), // チェックを外してアクティブに戻す
              showCheckbox: true, // チェックボックスを表示
              onDelete: () => _deleteTodo(todo), // 削除ボタンを表示
            ),
          ),
        );
      },
    );
  }
}