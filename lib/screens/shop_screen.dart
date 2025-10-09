import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/shop_item.dart';
import '../services/todo_service.dart';
import '../services/shop_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.todoService,
    this.onPointsChanged,
  });

  final TodoService todoService;
  final VoidCallback? onPointsChanged;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ShopService _shopService;
  int _currentPoints = 0;
  List<String> _purchasedItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shopService = ShopService(widget.todoService.prefs);
    _loadData();
  }

  Future<void> _loadData() async {
    final points = await widget.todoService.pointService.getPoints();
    final purchased = await _shopService.getPurchasedItems();

    setState(() {
      _currentPoints = points;
      _purchasedItems = purchased;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _purchaseItem(ShopItem item) async {
    if (_currentPoints < item.price) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイントが足りません！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_purchasedItems.contains(item.id)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('既に購入済みです'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入確認'),
        content: Text('「${item.name}」を${item.price}ポイントで購入しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('購入'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ポイントを消費
        await widget.todoService.pointService.spendPoints(item.price);
        // アイテムを購入
        await _shopService.purchaseItem(item.id, item.price);

        // データを再読み込み
        await _loadData();

        // 親にポイント変更を通知
        widget.onPointsChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「${item.name}」を購入しました！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('購入に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildItemCard(ShopItem item) {
    final isPurchased = _purchasedItems.contains(item.id);
    final canAfford = _currentPoints >= item.price;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            const SizedBox(height: 8),
            // プレビュー表示エリア
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: item.type == 'background'
                  ? (item.previewPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item.previewPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    '背景プレビュー\n${item.name}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              '背景プレビュー\n${item.name}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                
                              ),
                            ),
                          ))
                  : Center(
                      child: Text(
                        'サンプルテキスト',
                        style: TextStyle(
                          fontFamily: item.assetPath,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: isPurchased
                      ? null
                      : (canAfford ? () => _purchaseItem(item) : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPurchased
                        ? Colors.grey
                        : (canAfford ? Colors.blue : Colors.grey.shade400),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isPurchased ? '購入済み' : (canAfford ? '購入' : 'ポイント不足'),
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundItems = _shopService.getItemsByType('background');
    final fontItems = _shopService.getItemsByType('font');

    return Scaffold(
      backgroundColor: Colors.transparent, // 透明にして親の背景を表示
      appBar: AppBar(
        toolbarHeight: 0, // タイトルエリアを非表示にして隙間を無くす
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '背景', icon: Icon(Icons.wallpaper)),
            Tab(text: 'フォント', icon: Icon(Icons.font_download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 背景タブ
          ListView.builder(
            itemCount: backgroundItems.length,
            itemBuilder: (context, index) {
              return _buildItemCard(backgroundItems[index]);
            },
          ),
          // フォントタブ
          ListView.builder(
            itemCount: fontItems.length,
            itemBuilder: (context, index) {
              return _buildItemCard(fontItems[index]);
            },
          ),
        ],
      ),
    );
  }
}
