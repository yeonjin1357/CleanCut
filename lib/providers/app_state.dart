import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  List<String> _processedImages = [];
  
  List<String> get processedImages => _processedImages;
  
  void addProcessedImage(String path) {
    _processedImages.add(path);
    notifyListeners();
  }
  
  void clearHistory() {
    _processedImages.clear();
    notifyListeners();
  }
}