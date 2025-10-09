import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.todoService});

  final TodoService todoService;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Todo>> _selectedTodos;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Todo> _allTodos = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedTodos = ValueNotifier(_getTodosForDay(_selectedDay!));
    _loadTodos();
  }

  @override
  void dispose() {
    _selectedTodos.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final todos = await widget.todoService.getTodos();
    setState(() {
      _allTodos = todos;
      _selectedTodos.value = _getTodosForDay(_selectedDay!);
    });
  }

  List<Todo> _getTodosForDay(DateTime day) {
    final todosForDay = _allTodos.where((todo) {
      return isSameDay(todo.dueDate, day);
    }).toList();
    // 時間順にソート（期限が早い順）
    todosForDay.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return todosForDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedTodos.value = _getTodosForDay(selectedDay);
      });
    }
  }

  // カスタムマーカービルダー
  Widget _buildMarker(BuildContext context, DateTime day, List<Todo> todos) {
    if (todos.isEmpty) return const SizedBox.shrink();

    // TODOが1つの場合
    if (todos.length == 1) {
      final todoColor = todos.first.category?.color ?? Colors.blue;
      return Container(
        margin: const EdgeInsets.only(top: 25),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: todoColor, shape: BoxShape.circle),
        ),
      );
    }

    // 複数のTODOがある場合、最大3つまでのマーカーを表示
    final displayTodos = todos.take(3).toList();
    return Container(
      margin: const EdgeInsets.only(top: 25),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: displayTodos.asMap().entries.map((entry) {
          final index = entry.key;
          final todo = entry.value;
          final todoColor = todo.category?.color ?? Colors.blue;

          return Container(
            margin: EdgeInsets.only(left: index > 0 ? 1 : 0),
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: todoColor, shape: BoxShape.circle),
          );
        }).toList(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        children: [
          TableCalendar<Todo>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getTodosForDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
              holidayTextStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: _buildMarker,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Todo>>(
              valueListenable: _selectedTodos,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedDay != null
                          ? '${DateFormat('M月d日(E)', 'ja').format(_selectedDay!)}のTODOはありません'
                          : 'この日のTODOはありません',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), // 下部に余白を追加
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final todo = value[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TodoCard(
                        todo: todo,
                        onToggle: () async {
                          await widget.todoService.moveToCompleted(todo);
                          _loadTodos(); // リストを再読み込み
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
