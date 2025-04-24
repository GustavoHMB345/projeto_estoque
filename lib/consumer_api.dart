import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final Logger _logger = Logger('AuthManager');

class AuthManager {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static final FocusManager _focusManager = FocusManager.instance;

  static bool get isLoggedIn => _focusManager.primaryFocus != null;

  static void login() {
    _logger.info('Usuário conectado');
    _navigatorKey.currentState?.pushNamed('/home');
  }
}

Future<List<Map<String, dynamic>>> fetchDados(String pesquisa) async {
  final client = http.Client();

  try {
    // URL da rota para acessar a tabela aparatos
    final response = await client.get(
      Uri.parse('http://192.168.2.112:3000/aparatos?pesquisa=$pesquisa'),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  } catch (e) {
    print('Erro na requisição: $e');
    return [];
  } finally {
    client.close();
  }
}
