import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart'; // 作成したTodoクラス
import '../services/todo_service.dart'; // データ保存サービス
import '../widgets/todo_card.dart'; // 作成したTodoCardウィジェット
import '../screens/edit_todo_screen.dart'; // 編集画面

class TodoList extends StatefulWidget {
  const TodoList({super.key, required this.todoService, this.onTodoCompleted});

  final TodoService todoService; // ← 追加
  final VoidCallback? onTodoCompleted; // 完了時のコールバック

  @override
  State<TodoList> createState() => TodoListState();
}

class TodoListState extends State<TodoList> with TickerProviderStateMixin {
  List<Todo> _todos = [];
  bool _isLoading = true;
  final Map<String, AnimationController> _completionAnimations = {};
  final Map<String, Animation<double>> _scaleAnimations = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  final Set<String> _completingTodos = {};

  @override
  void initState() {
    super.initState();
    _loadTodos(); // SharedPreferences から読み込み
  }

  Future<void> _loadTodos() async {
    final todos = await widget.todoService.getTodos();
    // 期限順にソート
    todos.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  // 追加画面から呼ばれる
  void addTodo(Todo newTodo) async {
    _todos.add(newTodo);
    // 期限順にソート
    _todos.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    setState(() {});
    await widget.todoService.saveTodos(_todos);
  }

  // チェックボタンから呼ばれる（完了済みに移動）
  Future<void> _completeTodo(Todo todo) async {
    if (_completingTodos.contains(todo.id)) return; // 既にアニメーション中の場合は無視
    
    setState(() {
      _completingTodos.add(todo.id);
    });

    // アニメーションコントローラーを作成
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    _completionAnimations[todo.id] = controller;
    _scaleAnimations[todo.id] = scaleAnimation;
    _fadeAnimations[todo.id] = fadeAnimation;

    // アニメーション開始
    await controller.forward();
    
    // アニメーション完了後にTODOを移動
    await widget.todoService.moveToCompleted(todo);
    
    // クリーンアップ
    controller.dispose();
    _completionAnimations.remove(todo.id);
    _scaleAnimations.remove(todo.id);
    _fadeAnimations.remove(todo.id);
    _completingTodos.remove(todo.id);
    
    _loadTodos(); // リストを再読み込み
    widget.onTodoCompleted?.call(); // 親画面に完了を通知
  }

  // 編集ボタンから呼ばれる
  Future<void> _editTodo(Todo todo) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTodoScreen(
          todoService: widget.todoService,
          todo: todo,
        ),
      ),
    );

    if (result == true) {
      _loadTodos(); // リストを再読み込み
    }
  }

  // 日付ヘッダーウィジェット
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todoDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    Color headerColor = Colors.grey.shade600;
    
    if (todoDate.isAtSameMomentAs(today)) {
      dateText = '今日 (${DateFormat('M月d日(E)', 'ja').format(date)})';
      headerColor = Colors.red.shade600;
    } else if (todoDate.isAtSameMomentAs(tomorrow)) {
      dateText = '明日 (${DateFormat('M月d日(E)', 'ja').format(date)})';
      headerColor = Colors.orange.shade600;
    } else if (todoDate.isBefore(today)) {
      dateText = '期限切れ (${DateFormat('M月d日(E)', 'ja').format(date)})';
      headerColor = Colors.red.shade800;
    } else {
      dateText = DateFormat('M月d日(E)', 'ja').format(date);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 8),
                  color: headerColor.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todos.isEmpty) {
      return const Center(
        child: Text(
          'TODOがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 日付ごとにグループ化
    final groupedTodos = <DateTime, List<Todo>>{};
    for (final todo in _todos) {
      final dateKey = DateTime(todo.dueDate.year, todo.dueDate.month, todo.dueDate.day);
      groupedTodos.putIfAbsent(dateKey, () => []).add(todo);
    }

    final sortedDates = groupedTodos.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // 下部に余白を追加
      itemCount: sortedDates.length * 2, // ヘッダーとコンテンツで2倍
      itemBuilder: (context, index) {
        if (index.isOdd) {
          // 奇数インデックス: TODOリスト
          final dateIndex = index ~/ 2;
          final date = sortedDates[dateIndex];
          final todosForDate = groupedTodos[date]!;
          
          return Column(
            children: todosForDate.map((todo) {
              final isCompleting = _completingTodos.contains(todo.id);
              final scaleAnimation = _scaleAnimations[todo.id];
              final fadeAnimation = _fadeAnimations[todo.id];
              
              Widget todoCard = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TodoCard(
                  todo: todo,
                  onToggle: () => _completeTodo(todo), // チェックで完了済みに移動
                  onEdit: () => _editTodo(todo), // 編集ボタンで編集画面へ
                ),
              );

              // アニメーション中の場合はAnimatedBuilderでラップ
              if (isCompleting && scaleAnimation != null && fadeAnimation != null) {
                todoCard = AnimatedBuilder(
                  animation: _completionAnimations[todo.id]!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: scaleAnimation.value,
                      child: Opacity(
                        opacity: fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: todoCard,
                );
              }

              return AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: todoCard,
              );
            }).toList(),
          );
        } else {
          // 偶数インデックス: 日付ヘッダー
          final dateIndex = index ~/ 2;
          final date = sortedDates[dateIndex];
          return _buildDateHeader(date);
        }
      },
    );
  }

  @override
  void dispose() {
    // すべてのアニメーションコントローラーを破棄
    for (final controller in _completionAnimations.values) {
      controller.dispose();
    }
    _completionAnimations.clear();
    _scaleAnimations.clear();
    _fadeAnimations.clear();
    _completingTodos.clear();
    super.dispose();
  }
}
