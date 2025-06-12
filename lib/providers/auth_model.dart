import 'package:flutter/material.dart';
import '../consumer_api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class AuthModel with ChangeNotifier {
  final GlobalKey<NavigatorState> _navigatorKey;
  bool _isAuthenticated = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static AuthModel? _instance;

  static AuthModel get instance {
    _instance ??= AuthModel(GlobalKey<NavigatorState>());
    return _instance!;
  }

  AuthModel(this._navigatorKey);

  bool get isAuthenticated => _isAuthenticated;
  TextEditingController get usernameController => _usernameController;
  TextEditingController get passwordController => _passwordController;

  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  void login(String username, String password) async {
    try {
      // Hash the password using SHA-256
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      final response = await http.post(
        Uri.parse('$apiBaseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'loginUsuario': username, 'senhaUsuario': hashedPassword}),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _usuario = Usuario.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
        _navigatorKey.currentState?.pushReplacementNamed('/home');
      } else {
        _isAuthenticated = false;
        notifyListeners();
      }
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
    _navigatorKey.currentState?.pushReplacementNamed('/login');
  }
}

class Usuario {
  final String idUsuario; // Adicionar o ID do usuário
  final String email;
  final String nome;

  Usuario({required this.idUsuario, required this.email, required this.nome}); // Atualizar construtor

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario']?.toString() ?? '', // Obter idUsuario e converter para String
      email: json['emailUsuario'] ?? '',
      nome: json['nomeUsuario'] ?? 'Usuário',
    );
  }
}