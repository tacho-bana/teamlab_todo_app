import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryService {
  static const String _storageKey = 'categories';
  final SharedPreferences _prefs;

  CategoryService(this._prefs);

  // 保存されているカテゴリーリストを読み込む
  Future<List<Category>> getCategories() async {
    final String? categoriesJson = _prefs.getString(_storageKey);

    if (categoriesJson == null) {
      // デフォルトカテゴリーを作成
      final defaultCategories = _createDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }

    final List<dynamic> decoded = jsonDecode(categoriesJson);
    return decoded.map((json) => Category.fromJson(json)).toList();
  }

  // カテゴリーリストを保存する
  Future<void> saveCategories(List<Category> categories) async {
    final List<Map<String, dynamic>> jsonData = 
        categories.map((category) => category.toJson()).toList();
    final String encoded = jsonEncode(jsonData);
    await _prefs.setString(_storageKey, encoded);
  }

  // カテゴリーを追加する
  Future<void> addCategory(Category category) async {
    final categories = await getCategories();
    categories.add(category);
    await saveCategories(categories);
  }

  // カテゴリーを更新する
  Future<void> updateCategory(Category updatedCategory) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index != -1) {
      categories[index] = updatedCategory;
      await saveCategories(categories);
    }
  }

  // カテゴリーを削除する
  Future<void> deleteCategory(String categoryId) async {
    final categories = await getCategories();
    categories.removeWhere((c) => c.id == categoryId);
    await saveCategories(categories);
  }

  // IDでカテゴリーを取得する
  Future<Category?> getCategoryById(String id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // デフォルトカテゴリーを作成
  List<Category> _createDefaultCategories() {
    return [
      Category(name: '仕事', color: Colors.blue),
      Category(name: '個人', color: Colors.green),
      Category(name: '学習', color: Colors.orange),
      Category(name: '健康', color: Colors.red),
    ];
  }
}