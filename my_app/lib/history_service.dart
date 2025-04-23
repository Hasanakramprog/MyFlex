// history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/history_model.dart';

class HistoryService {
  static const String _historyKey = 'watch_history';
  
  // Get all history items
  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    return historyJson
        .map((json) => HistoryItem.fromMap(jsonDecode(json)))
        .toList()
        ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt)); // Sort by most recent
  }
  
  // Add or update a history item
  Future<void> addToHistory(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    // Convert to a list of HistoryItem objects
    final List<HistoryItem> history = historyJson
        .map((json) => HistoryItem.fromMap(jsonDecode(json)))
        .toList();
    
    // Check if the video is already in history
    final existingIndex = history.indexWhere((h) => h.videoId == item.videoId);
    
    if (existingIndex != -1) {
      // Update existing entry
      history.removeAt(existingIndex);
    }
    
    // Add as the most recent item
    history.insert(0, item);
    
    // Limit history to 100 items
    if (history.length > 100) {
      history.removeLast();
    }
    
    // Save back to shared preferences
    await prefs.setStringList(
      _historyKey,
      history.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }
  
  // Update an existing history item (by videoId)
  Future<void> updateHistoryItem(HistoryItem updatedItem) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    // Convert to a list of HistoryItem objects
    final List<HistoryItem> history = historyJson
        .map((json) => HistoryItem.fromMap(jsonDecode(json)))
        .toList();
    
    // Find and update the existing item
    final existingIndex = history.indexWhere((h) => h.videoId == updatedItem.videoId);
    
    if (existingIndex != -1) {
      // Replace the existing item
      history[existingIndex] = updatedItem;
      
      // If it's a significant update (e.g. watched more), move it to the top
      if (updatedItem.watchProgress > 10) {
        final item = history.removeAt(existingIndex);
        history.insert(0, item);
      }
      
      // Save back to shared preferences
      await prefs.setStringList(
        _historyKey,
        history.map((item) => jsonEncode(item.toMap())).toList(),
      );
    }
  }
  
  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  // Remove a specific item from history
  Future<void> removeFromHistory(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    // Convert to a list of HistoryItem objects
    final List<HistoryItem> history = historyJson
        .map((json) => HistoryItem.fromMap(jsonDecode(json)))
        .toList();
    
    // Remove the item with matching videoId
    history.removeWhere((item) => item.videoId == videoId);
    
    // Save back to shared preferences
    await prefs.setStringList(
      _historyKey,
      history.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }
  
  // Get a specific history item by videoId
  Future<HistoryItem?> getHistoryItem(String videoId) async {
    final history = await getHistory();
    try {
      return history.firstWhere((item) => item.videoId == videoId);
    } catch (e) {
      return null; // Item not found in history
    }
  }
  Future<HistoryItem?> getLastWatchedVideo() async {
  final history = await getHistory();
  return history.isNotEmpty ? history.first : null;
}
}