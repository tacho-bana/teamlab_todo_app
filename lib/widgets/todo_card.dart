import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用パッケージ
import 'package:flutter_svg/flutter_svg.dart';
import '../models/todo.dart';

class TodoCard extends StatefulWidget {
  final Todo todo; // 表示する Todo データ
  final VoidCallback? onToggle; // 完了トグル用コールバック（任意）
  final bool showCheckbox; // チェックボックス表示フラグ
  final VoidCallback? onConvertToPoints; // ポイント変換用コールバック（任意）
  final VoidCallback? onEdit; // 編集用コールバック（任意）
  const TodoCard({
    super.key,
    required this.todo,
    this.onToggle,
    this.showCheckbox = true,
    this.onConvertToPoints,
    this.onEdit,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool? _localCompletedState;

  bool get _effectiveCompletedState => 
      _localCompletedState ?? widget.todo.isCompleted;

  void _handleToggle() {
    if (widget.onToggle != null) {
      setState(() {
        _localCompletedState = !_effectiveCompletedState;
      });
      widget.onToggle!();
      
      // 一定時間後にローカル状態をクリア（アニメーション完了を待つ）
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _localCompletedState = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.todo.category?.color ?? Colors.blue;

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
            if (widget.showCheckbox) ...[
              IconButton(
                iconSize: 24,
                icon: Icon(
                  _effectiveCompletedState
                      ? Icons
                            .check_circle // チェック済み
                      : Icons.radio_button_unchecked, // 未チェック
                  color: Colors.white,
                ),
                onPressed: _handleToggle,
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
                    widget.todo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.todo.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('M月d日(E)', 'ja').format(widget.todo.dueDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.todo.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.todo.category!.name,
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
            // 編集ボタン（アクティブTODOの場合のみ表示）
            if (widget.onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                iconSize: 20,
                tooltip: '編集',
              ),
            ],
            // ポイント変換ボタン（完了済みTODOの場合のみ表示）
            if (widget.onConvertToPoints != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onConvertToPoints,
                icon: SvgPicture.asset(
                  'assets/images/star_ch.svg',
                  width: 40,
                  height: 40,
                ),
                iconSize: 20,
                tooltip: 'ポイントに変換',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
