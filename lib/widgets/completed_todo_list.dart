import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_card.dart';

class CompletedTodoList extends StatefulWidget {
  const CompletedTodoList({
    super.key,
    required this.todoService,
    this.onTodoUncompleted,
    this.onPointsChanged,
  });

  final TodoService todoService;
  final VoidCallback? onTodoUncompleted; // アクティブに戻した時のコールバック
  final VoidCallback? onPointsChanged; // ポイント変更時のコールバック

  @override
  State<CompletedTodoList> createState() => CompletedTodoListState();
}

class CompletedTodoListState extends State<CompletedTodoList> with TickerProviderStateMixin {
  List<Todo> _completedTodos = [];
  bool _isLoading = true;
  final Map<String, AnimationController> _uncompleteAnimations = {};
  final Map<String, Animation<double>> _scaleAnimations = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  final Set<String> _uncompletingTodos = {};

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
    if (_uncompletingTodos.contains(todo.id)) return; // 既にアニメーション中の場合は無視
    
    setState(() {
      _uncompletingTodos.add(todo.id);
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

    _uncompleteAnimations[todo.id] = controller;
    _scaleAnimations[todo.id] = scaleAnimation;
    _fadeAnimations[todo.id] = fadeAnimation;

    // アニメーション開始
    await controller.forward();
    
    // アニメーション完了後にTODOを移動
    await widget.todoService.moveToActive(todo);
    
    // クリーンアップ
    controller.dispose();
    _uncompleteAnimations.remove(todo.id);
    _scaleAnimations.remove(todo.id);
    _fadeAnimations.remove(todo.id);
    _uncompletingTodos.remove(todo.id);
    
    _loadCompletedTodos(); // リストを再読み込み
    widget.onTodoUncompleted?.call(); // 親画面にアクティブ復帰を通知
  }

  // 完了済みTODOをポイントに変換する
  Future<void> _convertToPoints(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント変換'),
        content: Text('「${todo.title}」を星に変換しますか？\nTODOは削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変換'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final points = await widget.todoService.convertCompletedTodoToPoints(
        todo,
      );
      _loadCompletedTodos(); // リストを再読み込み
      widget.onPointsChanged?.call(); // ポイント変更を通知

      // ポイント獲得のスナックバーを表示
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${points}ポイント獲得しました！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // すべての完了済みTODOをポイントに変換する
  Future<void> _convertAllToPoints() async {
    if (_completedTodos.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('一括ポイント変換'),
        content: Text(
          'すべての完了済みTODO（${_completedTodos.length}件）を${_completedTodos.length}ポイントに変換しますか？\nすべてのTODOが削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変換'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final totalPoints = await widget.todoService
          .convertAllCompletedTodosToPoints();
      _loadCompletedTodos(); // リストを再読み込み
      widget.onPointsChanged?.call(); // ポイント変更を通知

      // ポイント獲得のスナックバーを表示
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${totalPoints}ポイント獲得しました！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

    return Column(
      children: [
        // 一括変換ボタン
        if (_completedTodos.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _convertAllToPoints,
              icon: SvgPicture.asset(
                'assets/images/star.svg',
                width: 24,
                height: 24,
              ),
              label: Text(
                'すべて星に変換 (${_completedTodos.length}件)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        // TODOリスト
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // 下部に余白を追加
            itemCount: _completedTodos.length,
            itemBuilder: (context, index) {
              final todo = _completedTodos[index];
              final isUncompleting = _uncompletingTodos.contains(todo.id);
              final scaleAnimation = _scaleAnimations[todo.id];
              final fadeAnimation = _fadeAnimations[todo.id];
              
              Widget todoCard = Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.7, // 完了済みは少し薄く表示
                  child: TodoCard(
                    todo: todo,
                    onToggle: () => _moveToActive(todo), // チェックを外してアクティブに戻す
                    showCheckbox: true, // チェックボックスを表示
                    onConvertToPoints: () =>
                        _convertToPoints(todo), // ポイント変換ボタンを表示
                  ),
                ),
              );

              // アニメーション中の場合はAnimatedBuilderでラップ
              if (isUncompleting && scaleAnimation != null && fadeAnimation != null) {
                todoCard = AnimatedBuilder(
                  animation: _uncompleteAnimations[todo.id]!,
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
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // すべてのアニメーションコントローラーを破棄
    for (final controller in _uncompleteAnimations.values) {
      controller.dispose();
    }
    _uncompleteAnimations.clear();
    _scaleAnimations.clear();
    _fadeAnimations.clear();
    _uncompletingTodos.clear();
    super.dispose();
  }
}
