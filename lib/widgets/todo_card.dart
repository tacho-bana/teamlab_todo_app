import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用パッケージ
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo; // 表示する Todo データ
  final VoidCallback? onToggle; // 完了トグル用コールバック（任意）
  final bool showCheckbox; // チェックボックス表示フラグ
  final VoidCallback? onDelete; // 削除用コールバック（任意）
  const TodoCard({super.key, required this.todo, this.onToggle, this.showCheckbox = true, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cardColor = todo.category?.color ?? Colors.blue;
    
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: SizedBox(
        width: double.infinity, // コンポーネントの領域をスマホの横幅に合わせて横幅いっぱいに取る
        height: 75,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 左端：チェックアイコン（タップでトグル）
            if (showCheckbox) ...[
              IconButton(
                iconSize: 24,
                icon: Icon(
                  todo.isCompleted
                      ? Icons
                            .check_circle // チェック済み
                      : Icons.radio_button_unchecked, // 未チェック
                  color: Colors.white,
                ),
                onPressed: onToggle,
              ),
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 16), // チェックボックスがない場合の余白
            ],
            // ── テキスト群
            Expanded(
              // ↓Expandedを利用し、利用できる水平領域をすべて埋めるようにする
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    todo.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('M月d日(E)', 'ja').format(todo.dueDate),
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      if (todo.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            todo.category!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 削除ボタン（完了済みTODOの場合のみ表示）
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                color: Colors.white,
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
