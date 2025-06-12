import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../models/categoria.dart';
import '../consumer_api.dart' as api;

class AppState with ChangeNotifier {
  String _headerText = 'Drawer';
  MainAxisAlignment _mainAxisAlignment = MainAxisAlignment.spaceBetween;
  bool _isLoggedIn = false;
  List<Produto> _produtos = [];
  List<Categoria> _categorias = [];
  bool _isLoadingProdutos = false;

  String get headerText => _headerText;
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  bool get isLoggedIn => _isLoggedIn;
  List<Produto> get produtos => _produtos;
  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoadingProdutos;

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

  void setCategorias(List<Categoria> novasCategorias) {
    _categorias = novasCategorias;
    notifyListeners();
  }

  Future<void> carregarProdutosDaApi() async {
    _isLoadingProdutos = true;
    notifyListeners();
    try {
      final dados = await api.fetchDados('produtos');
      _produtos = dados.map<Produto>((json) => Produto.fromJson(json)).toList();
    } catch (e) {
      _produtos = [];
    } finally {
      _isLoadingProdutos = false;
      notifyListeners();
    }
  }
}