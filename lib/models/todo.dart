import 'package:uuid/uuid.dart'; // 一意なIDを生成するライブラリ
import 'category.dart';

class Todo {
  final String id; // 各タスクの固有識別番号
  final String title; // タスクのタイトル（例：「レポートを書く」）
  final String detail; // タスクの詳細（例：「心理学のレポート、2000字」）
  final DateTime dueDate; // 期日（例：DateTime(2025, 4, 1)）
  final bool isCompleted; // チェック済みかどうか（true: 完了, false: 未完了）
  final DateTime? completedDate; // 完了日（完了時に記録）
  final Category? category; // カテゴリー（任意）

  Todo({
    String? id, // IDが指定されない場合は自動生成
    required this.title, // タイトルは必須
    required this.detail, // 詳細も必須
    required this.dueDate, // 期日も必須
    this.isCompleted = false, // デフォルトは「未完了」
    this.completedDate, // 完了日（任意）
    this.category, // カテゴリーは任意
  }) : id = id ?? const Uuid().v4(); // IDの自動生成

  // 既存のTodoを一部変更したコピーを作成するメソッド
  Todo copyWith({
    String? title,
    String? detail,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedDate,
    Category? category,
  }) {
    return Todo(
      id: id, // IDは変更しない
      title: title ?? this.title, // 新しいタイトル or 元のタイトル
      detail: detail ?? this.detail, // 新しい詳細 or 元の詳細
      dueDate: dueDate ?? this.dueDate, // 新しい期日 or 元の期日は変更しない
      isCompleted: isCompleted ?? this.isCompleted, // 新しい状態 or 元の状態
      completedDate: completedDate ?? this.completedDate, // 新しい完了日 or 元の完了日
      category: category ?? this.category, // 新しいカテゴリー or 元のカテゴリー
    );
  }
}
