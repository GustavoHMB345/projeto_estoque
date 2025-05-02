import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/produto.dart';
import 'package:flutter/foundation.dart'; // Import for debugging

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
    final response = await client.get(
      Uri.parse('http://192.168.2.112:3000/$pesquisa'),
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

Future<List<Map<String, dynamic>>> fetchCategorias() async {
  final client = http.Client();

  try {
    final response = await client.get(
      Uri.parse('http://192.168.2.112:3000/categorias'),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  } catch (e) {
    _logger.severe('Erro na requisição: $e');
    return [];
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> fetchMovimentacoesEstoque() async {
  final client = http.Client();

  try {
    final response = await client.get(
      Uri.parse('http://192.168.2.112:3000/movimentacoes_estoque'),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  } catch (e) {
    _logger.severe('Erro na requisição: $e');
    return [];
  } finally {
    client.close();
  }
}

Future<bool> updateProduto(Produto produto) async {
  final client = http.Client();

  try {
    final payload = jsonEncode(produto.toJson());
    _logger.info('Enviando dados para atualização: $payload');

    final response = await client.put(
      Uri.parse('http://192.168.2.112:3000/produtos/${produto.id}'),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    _logger.info('Resposta da API: ${response.statusCode} - ${response.body}');

    return response.statusCode == 200;
  } catch (e) {
    _logger.severe('Erro ao atualizar o produto: $e');
    if (kDebugMode) {
      print('Erro ao atualizar o produto: $e'); // Log error in debugger
    }
    return false;
  } finally {
    client.close();
  }
}

Future<Produto> fetchProdutoAtualizado(String id) async {
  final response = await http.get(
    Uri.parse('http://192.168.2.112:3000/produtos/$id'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return Produto.fromJson(jsonData);
  } else {
    throw Exception('Erro ao buscar produto atualizado: ${response.statusCode}');
  }
}
