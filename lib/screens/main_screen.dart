import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/todo_service.dart';
import 'list_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import 'add_todo_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.todoService, this.onSettingsChanged});

  final TodoService todoService;
  final VoidCallback? onSettingsChanged;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // デフォルトでTODOリスト画面（中央）
  int _currentPoints = 0;
  final GlobalKey<ListScreenState> _listScreenKey = GlobalKey<ListScreenState>();

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await widget.todoService.pointService.getPoints();
    setState(() {
      _currentPoints = points;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _navigateToAddTodo() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(
          todoService: widget.todoService,
        ),
      ),
    );

    if (updated == true) {
      // TODO作成後はリスト画面に移動し、リストを更新
      setState(() {
        _currentIndex = 1; // リスト画面のインデックス
      });
      // リストを更新
      _listScreenKey.currentState?.refreshTodoLists();
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return ShopScreen(
          todoService: widget.todoService,
          onPointsChanged: _loadPoints,
        );
      case 1:
        return ListScreen(
          key: _listScreenKey,
          todoService: widget.todoService,
          onSettingsChanged: widget.onSettingsChanged,
          onPointsChanged: _loadPoints,
        );
      case 2:
        return SettingsScreen(
          todoService: widget.todoService,
          onSettingsChanged: () {
            print('Settings changed callback called'); // デバッグ用
            widget.onSettingsChanged?.call();
          },
        );
      default:
        return ListScreen(
          todoService: widget.todoService,
          onSettingsChanged: widget.onSettingsChanged,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 透明にして親の背景を表示
      appBar: AppBar(
        title: Image.asset(
          'assets/images/TODO.png',
          height: 48,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/star.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentPoints',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _getCurrentScreen(),
      floatingActionButton: _currentIndex == 1 
          ? FloatingActionButton(
              onPressed: _navigateToAddTodo,
              backgroundColor: const Color.fromARGB(255, 255, 232, 118),
              foregroundColor: const Color.fromARGB(255, 37, 66, 78),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ショップボタン
                _buildNavButton(
                  icon: Icons.store,
                  label: 'ショップ',
                  isSelected: _currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                
                // 中央のTODOリストボタン
                _buildNavButton(
                  icon: Icons.list_alt,
                  label: 'TODO',
                  isSelected: _currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                
                // 設定ボタン
                _buildNavButton(
                  icon: Icons.settings,
                  label: '設定',
                  isSelected: _currentIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}