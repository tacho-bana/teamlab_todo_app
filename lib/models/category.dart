import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;

  Category({
    String? id,
    required this.name,
    required this.color,
  }) : id = id ?? const Uuid().v4();

  // Color を int に変換（保存用）
  int get colorValue => color.value;

  // int から Color を作成（読み込み用）
  static Color colorFromValue(int value) => Color(value);

  // 既存のCategoryを一部変更したコピーを作成するメソッド
  Category copyWith({
    String? name,
    Color? color,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  // JSON変換用
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
    };
  }

  // JSONからCategoryを作成
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: colorFromValue(json['colorValue']),
    );
  }
}