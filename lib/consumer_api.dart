import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/produto.dart';
import 'package:flutter/foundation.dart'; // Import for debugging

final Logger _logger = Logger('AuthManager');
const String apiUrl = 'http://192.168.2.112:3000';

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

Future<bool> createProduto(Produto produto) async {
  if (produto.nome.isEmpty || produto.categoriaId.isEmpty || produto.unidade.isEmpty || produto.quantidade <= 0) {
    _logger.severe('Erro: Dados inválidos para o produto. Verifique os campos obrigatórios.');
    return false;
  }

  final url = Uri.parse('http://localhost:3000/produtos');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(produto.toJson()),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    _logger.severe('Erro ao criar produto: Código de status ${response.statusCode}, Resposta: ${response.body}');
    return false;
  }
}

Future<bool> createCategoria(String categoria) async {
  final url = Uri.parse('$apiUrl/categorias');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'nome': categoria}),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    debugPrint('Erro ao criar categoria: ${response.body}');
    return false;
  }
}

// Removendo a integração de 'id' nas funções relacionadas a categorias e produtos
Future<Produto> fetchProdutoAtualizado(String id) async {
  throw Exception('Função desativada devido à remoção de id');
}

Future<bool> updateProduto(Produto produto) async {
  throw Exception('Função desativada devido à remoção de id');
}
