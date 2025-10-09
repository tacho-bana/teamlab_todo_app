class ShopItem {
  final String id;
  final String name;
  final String type; // 'background' or 'font'
  final int price;
  final String assetPath; // 背景画像のパスまたはフォント名
  final String? previewPath; // プレビュー用の小さな画像パス
  
  ShopItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.assetPath,
    this.previewPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'assetPath': assetPath,
      'previewPath': previewPath,
    };
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      price: json['price'],
      assetPath: json['assetPath'],
      previewPath: json['previewPath'],
    );
  }
}