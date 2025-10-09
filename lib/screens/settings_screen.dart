import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../services/shop_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.todoService,
    this.onSettingsChanged,
  });

  final TodoService todoService;
  final VoidCallback? onSettingsChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ShopService _shopService;
  late SettingsService _settingsService;

  String _selectedBackground = 'bg_default';
  String _selectedFont = 'font_yomogi';
  List<String> _purchasedItems = [];

  @override
  void initState() {
    super.initState();
    _shopService = ShopService(widget.todoService.prefs);
    _settingsService = SettingsService(widget.todoService.prefs);
    _loadData();
  }

  Future<void> _loadData() async {
    final background = await _settingsService.getSelectedBackground();
    final font = await _settingsService.getSelectedFont();
    final purchased = await _shopService.getPurchasedItems();

    setState(() {
      _selectedBackground = background;
      _selectedFont = font;
      _purchasedItems = purchased;
    });
  }

  Future<void> _updateBackground(String backgroundPath) async {
    print('Updating background to: $backgroundPath'); // デバッグ用
    await _settingsService.setSelectedBackground(backgroundPath);
    setState(() {
      _selectedBackground = backgroundPath;
    });

    // 親に設定変更を通知
    widget.onSettingsChanged?.call();

    // 既存のSnackBarを削除してから新しいものを表示
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('背景を変更しました！'), backgroundColor: Colors.green),
    );
  }

  Future<void> _updateFont(String fontId) async {
    await _settingsService.setSelectedFont(fontId);
    setState(() {
      _selectedFont = fontId;
    });

    // 親に設定変更を通知
    widget.onSettingsChanged?.call();

    // 既存のSnackBarを削除してから新しいものを表示
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フォントを変更しました！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBackgroundSelector() {
    final backgroundItems = _shopService
        .getItemsByType('background')
        .where((item) => _purchasedItems.contains(item.id))
        .toList();

    // デフォルト背景オプションを追加
    final hasDefaultSelected = _selectedBackground == 'default';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '背景設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // デフォルト背景
                GestureDetector(
                  onTap: () => _updateBackground('default'),
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasDefaultSelected ? Colors.blue : Colors.grey,
                        width: hasDefaultSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(
                      child: Text(
                        'デフォルト',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontFamily: 'Yomogi'),
                      ),
                    ),
                  ),
                ),
                // 購入済み背景
                ...backgroundItems.map((item) {
                  final isSelected = _selectedBackground == item.assetPath;
                  return GestureDetector(
                    onTap: () => _updateBackground(item.assetPath),
                    child: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.previewPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                item.previewPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector() {
    final fontItems = _shopService
        .getItemsByType('font')
        .where((item) => _purchasedItems.contains(item.id))
        .toList();

    // デフォルトフォントの選択状態
    final hasDefaultSelected = _selectedFont == 'Yomogi';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'フォント設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            const SizedBox(height: 16),
            // デフォルトフォント
            Card(
              color: hasDefaultSelected ? Colors.blue.shade50 : null,
              child: ListTile(
                title: const Text(
                  'デフォルト',
                  style: TextStyle(
                    fontFamily: 'Yomogi',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'サンプルテキスト - これはプレビューです',
                  style: TextStyle(fontFamily: 'Yomogi'),
                ),
                trailing: hasDefaultSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => _updateFont('Yomogi'),
              ),
            ),
            // 購入済みフォント
            ...fontItems.map((item) {
              final isSelected = _selectedFont == item.assetPath;
              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: item.assetPath,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'サンプルテキスト - これはプレビューです',
                    style: TextStyle(fontFamily: item.assetPath),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => _updateFont(item.assetPath),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 透明にして親の背景を表示
      appBar: AppBar(
        toolbarHeight: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('設定リセット'),
                  content: const Text('すべての設定をデフォルトに戻しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('リセット'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _settingsService.resetSettings();
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('設定をリセットしました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBackgroundSelector(),
          const SizedBox(height: 16),
          _buildFontSelector(),
        ],
      ),
    );
  }
}
