class Todo {
  final String title; // タスクのタイトル（例：「レポートを書く」）
  final String detail; // タスクの詳細（例：「心理学のレポート、2000字」）
  final DateTime dueDate; // 期日（例：DateTime(2025, 4, 1)）
  final bool isCompleted; // チェック済みかどうか（true: 完了, false: 未完了）

  // コンストラクタ（TODOを作成する時の決まり）
  Todo({
    required this.title, // タイトルは必須
    required this.detail, // 詳細も必須
    required this.dueDate, // 期日も必須
    this.isCompleted = false, // デフォルトは「未完了」
  });
}
