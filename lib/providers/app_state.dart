import 'package:flutter/material.dart';

class AppState with ChangeNotifier {
  String _headerText = 'Drawer';
  MainAxisAlignment _mainAxisAlignment = MainAxisAlignment.spaceBetween;
  bool _isLoggedIn = false;

  String get headerText => _headerText;
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  bool get isLoggedIn => _isLoggedIn;

  void updateHeaderText(String newText) {
    _headerText = newText;
    notifyListeners();
  }

  void updateMainAxisAlignment(MainAxisAlignment newMainAxisAlignment) {
    _mainAxisAlignment = newMainAxisAlignment;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}