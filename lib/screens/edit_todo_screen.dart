import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../models/category.dart';
import '../services/todo_service.dart';
import 'category_management_screen.dart';

class EditTodoScreen extends StatefulWidget {
  const EditTodoScreen({super.key, required this.todoService, required this.todo});

  final TodoService todoService;
  final Todo todo;

  @override
  EditTodoScreenState createState() => EditTodoScreenState();
}

class EditTodoScreenState extends State<EditTodoScreen> {
  // 入力内容を管理するコントローラー
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;
  Category? _selectedCategory;
  List<Category> _categories = [];

  // フォームの入力検証用
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // 既存のTODOデータで初期化
    _titleController.text = widget.todo.title;
    _detailController.text = widget.todo.detail;
    _selectedDate = widget.todo.dueDate;
    _selectedCategory = widget.todo.category;
    _dateController.text = DateFormat('yyyy年MM月dd日').format(widget.todo.dueDate);
    
    // リスナー設定
    _titleController.addListener(_updateFormValid);
    _dateController.addListener(_updateFormValid);
    
    // カテゴリーを読み込んでから初期状態チェック
    _loadCategories().then((_) {
      _updateFormValid();
    });
  }

  Future<void> _loadCategories() async {
    final categories = await widget.todoService.categoryService.getCategories();
    setState(() {
      _categories = categories;
      // 現在選択されているカテゴリーが読み込まれたカテゴリーリストに存在するかチェック
      if (_selectedCategory != null) {
        try {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == _selectedCategory!.id,
          );
        } catch (e) {
          // カテゴリーが見つからない場合はnullに設定
          _selectedCategory = null;
        }
      }
    });
  }

  void _updateFormValid() {
    setState(() {
      _isFormValid =
          _titleController.text.isNotEmpty &&
          _selectedDate != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タスクを編集')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // タイトル入力フィールド
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タスクのタイトル',
                  hintText: '20文字以内で入力してください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              // 詳細入力フィールド
              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'タスクの詳細（任意）',
                  hintText: '詳細情報があれば入力してください',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 期日入力フィールド
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: '期日',
                  hintText: '期日を選択してください',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text = DateFormat('yyyy年MM月dd日').format(picked);
                    });
                    _updateFormValid();
                  }
                },
                validator: (value) {
                  if (_selectedDate == null) {
                    return '期日を選択してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // カテゴリー選択
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリー（任意）',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('カテゴリーを選択'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? newCategory) {
                        setState(() {
                          _selectedCategory = newCategory;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryManagementScreen(
                            categoryService: widget.todoService.categoryService,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadCategories();
                      }
                    },
                    icon: const Icon(Icons.settings),
                    tooltip: 'カテゴリー管理',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 保存ボタン
              ElevatedButton(
                onPressed: _isFormValid ? _saveTodo : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color.fromARGB(255, 0, 0, 255)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  '変更を保存',
                  style: TextStyle(
                    color: _isFormValid ? Colors.white : Colors.grey,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // タスク編集処理
  void _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      // 編集されたTodoを作成
      Todo editedTodo = Todo(
        title: _titleController.text,
        detail: _detailController.text.isEmpty ? '' : _detailController.text,
        dueDate: _selectedDate!,
        category: _selectedCategory,
      );

      // TODOを更新
      await widget.todoService.editTodo(widget.todo, editedTodo);

      if (!mounted) return;

      // 前の画面へ「更新したよ」と知らせる
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}