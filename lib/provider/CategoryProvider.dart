import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../service/CategoryService.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<CategoryModel> _categories = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize categories for new user
  Future<void> initializeDefaultCategories() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _categoryService.initializeDefaultCategories();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all categories
  void loadCategories() {
    _categoryService.getUserCategories().listen((categories) {
      _categories = categories;
      _expenseCategories = categories.where((c) => c.type == 'expense').toList();
      _incomeCategories = categories.where((c) => c.type == 'income').toList();
      notifyListeners();
    });
  }

  // Add category
  Future<void> addCategory(CategoryModel category) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _categoryService.addCategory(category);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoryService.updateCategory(category);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoryService.deleteCategory(categoryId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category statistics
  Future<Map<String, dynamic>> getCategoryStats(String categoryId) async {
    return await _categoryService.getCategoryStats(categoryId);
  }
}