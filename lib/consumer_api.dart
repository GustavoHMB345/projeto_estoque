import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 

final Logger _logger = Logger('AuthManager');
const String apiBaseUrl = 'http://192.168.2.112:3000';

class AuthManager {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static final FocusManager _focusManager = FocusManager.instance;

  static bool get isLoggedIn => _focusManager.primaryFocus != null;

  static void login() {
    _logger.info('Usuário conectado');
    _navigatorKey.currentState?.pushNamed('/home');
  }
}

Future<List<Map<String, dynamic>>> fetchDados(String endpoint) async {
  final client = http.Client();
  try {
    final response = await client.get(
      Uri.parse('$apiBaseUrl/$endpoint'),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    _logger.severe('Erro na requisição: $e');
    throw Exception('Erro ao conectar ao servidor: $e');
  } finally {
    client.close();
  }
}

Future<bool> createItem(String endpoint, Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/$endpoint'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  return response.statusCode == 201;
}

Future<bool> updateItem(String endpoint, String id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse('$apiBaseUrl/$endpoint/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  return response.statusCode == 200;
}

Future<bool> deleteItem(String endpoint, String id) async {
  final response = await http.delete(
    Uri.parse('$apiBaseUrl/$endpoint/$id'),
  );
  return response.statusCode == 200;
}

Future<List<Map<String, dynamic>>> fetchUsuarios() async {
  try {
    final response = await http.get(Uri.parse('$apiBaseUrl/usuarios/tableusuario')).timeout(const Duration(seconds: 30));
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Falha ao carregar usuários');
    }
  } catch (e) {
    print('Erro ao executar fetchUsuarios: $e');
    rethrow;
  }
}

Future<void> createUsuario(Map<String, dynamic> usuario) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/usuarios'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(usuario),
  );
  if (response.statusCode != 201) {
    throw Exception('Falha ao criar usuário');
  }
}

Future<void> deleteUsuario(String id) async {
  final response = await http.delete(Uri.parse('$apiBaseUrl/usuarios/$id'));
  if (response.statusCode != 200) {
    throw Exception('Falha ao excluir usuário');
  }
}

// Funções genéricas para CRUD já estão corretas, não precisa alterar.
