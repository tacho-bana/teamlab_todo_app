import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'services/todo_service.dart';
import 'services/settings_service.dart';
import 'services/shop_service.dart';

void main() async {
  // Flutter のプラグイン初期化。非同期処理を行う場合は必須
  WidgetsFlutterBinding.ensureInitialized();

  // DateFormat で日本語表記を使えるようロケールを初期化
  await initializeDateFormatting('ja'); // 他言語の場合は"en"などに変更

  // ① SharedPreferences を初期化（端末に小さなキー／バリューで保存できる）
  final prefs = await SharedPreferences.getInstance();

  // ② SharedPreferences を使って TodoService を生成（保存・読み込みの窓口）
  final todoService = TodoService(prefs);

  // ③ TodoService をアプリ全体へ渡す
  runApp(MyApp(todoService: todoService));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.todoService});

  // アプリ全体で共有する TodoService
  final TodoService todoService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsService _settingsService;
  late ShopService _shopService;
  String _currentFont = 'Yomogi';
  String _currentBackground = 'default';

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(widget.todoService.prefs);
    _shopService = ShopService(widget.todoService.prefs);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontPath = await _settingsService.getSelectedFont();
    final backgroundPath = await _settingsService.getSelectedBackground();
    
    print('Loading settings - Font: $fontPath, Background: $backgroundPath'); // デバッグ用
    
    if (mounted) {
      setState(() {
        _currentFont = fontPath;
        _currentBackground = backgroundPath;
        print('State updated - Font: $_currentFont, Background: $_currentBackground'); // デバッグ用
      });
      
      // 強制的に再描画を促す
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building MyApp with background: $_currentBackground'); // デバッグ用
    
    return MaterialApp(
      // ListScreen にtodoServiceを引数としてわたす
      home: Container(
        decoration: _currentBackground != 'default'
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_currentBackground),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    print('Background image error: $exception');
                    print('Path: $_currentBackground');
                  },
                ),
              )
            : BoxDecoration(
                color: Colors.white, // デフォルト背景色
              ),
        child: MainScreen(
          todoService: widget.todoService,
          onSettingsChanged: _loadSettings,
        ),
      ),
      theme: ThemeData(
        fontFamily: _currentFont,
      ),
    );
  }
}
