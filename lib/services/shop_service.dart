import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_item.dart';

class ShopService {
  static const String _purchasedItemsKey = 'purchased_items';
  final SharedPreferences _prefs;

  ShopService(this._prefs);

  // 利用可能なアイテムのリスト（実際のアプリではサーバーから取得する場合もある）
  List<ShopItem> get availableItems => [
    // 背景
    ShopItem(
      id: 'bg_haikei1',
      name: '背景1',
      type: 'background',
      price: 2,
      assetPath: 'assets/images/haikei1.jpg',
      previewPath: 'assets/images/haikei1.jpg',
    ),
    ShopItem(
      id: 'bg_sunset',
      name: '背景2',
      type: 'background',
      price: 3,
      assetPath: 'assets/images/haikei2.jpeg',
      previewPath: 'assets/images/haikei2.jpeg',
    ),
    ShopItem(
      id: 'bg_forest',
      name: '背景3',
      type: 'background',
      price: 20,
      assetPath: 'assets/images/haikei3.jpeg',
      previewPath: 'assets/images/haikei3.jpeg',
    ),

    // フォント
    ShopItem(
      id: 'font_chalk',
      name: 'フォント1',
      type: 'font',
      price: 2,
      assetPath: 'Chalk-S-JP',
    ),
    ShopItem(
      id: 'font_lefthanded',
      name: 'フォント2',
      type: 'font',
      price: 8,
      assetPath: 'LeftHanded',
    ),
    ShopItem(
      id: 'font_yomogi2',
      name: 'フォント3',
      type: 'font',
      price: 12,
      assetPath: 'Yomogi',
    ),
  ];

  // 購入済みアイテムを取得
  Future<List<String>> getPurchasedItems() async {
    final String? purchasedJson = _prefs.getString(_purchasedItemsKey);
    if (purchasedJson == null) {
      // 最初は何も購入していない状態
      return [];
    }

    final List<dynamic> decoded = jsonDecode(purchasedJson);
    return decoded.cast<String>();
  }

  // アイテムを購入
  Future<bool> purchaseItem(String itemId, int cost) async {
    final purchasedItems = await getPurchasedItems();

    // 既に購入済みの場合
    if (purchasedItems.contains(itemId)) {
      return false;
    }

    // アイテムが存在するかチェック
    final item = availableItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    // ポイントが足りるかチェック（外部で行う前提）
    purchasedItems.add(itemId);

    final String encoded = jsonEncode(purchasedItems);
    await _prefs.setString(_purchasedItemsKey, encoded);

    return true;
  }

  // アイテムが購入済みかチェック
  Future<bool> isPurchased(String itemId) async {
    final purchasedItems = await getPurchasedItems();
    return purchasedItems.contains(itemId);
  }

  // タイプ別のアイテムを取得
  List<ShopItem> getItemsByType(String type) {
    return availableItems.where((item) => item.type == type).toList();
  }

  // IDでアイテムを取得
  ShopItem? getItemById(String id) {
    try {
      return availableItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
