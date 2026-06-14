import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseService {

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  List<Map<String, dynamic>> _allTasks = [];
  bool _isInitialized = false;

  // 1. Initial Load: This reads your JSON file once when the app starts
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // It looks for your file in the path we set up earlier
      final String response = await rootBundle.loadString('lib/data/dummy_json/tasks.json');
      final List<dynamic> data = json.decode(response);

      // Convert dynamic list to a list of Maps we can work with
      _allTasks = List<Map<String, dynamic>>.from(data);
      _isInitialized = true;
      print("Database initialized with ${_allTasks.length} tasks from JSON.");
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }

  List<Map<String, dynamic>> get tasks => _allTasks;

  void addTask(Map<String, dynamic> newTask) {
    _allTasks.insert(0, newTask);
    print("New task added! Total tasks: ${_allTasks.length}");
  }
}