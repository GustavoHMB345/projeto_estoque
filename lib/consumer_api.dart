import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/produto.dart';
import 'package:flutter/foundation.dart'; 

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
  final criadoEmFormatado = produto.criadoEm.toIso8601String().split('T')[0]; // Formatar a data

  print('Dados enviados para a API: ${produto.toJson()}'); // Log dos dados enviados

  if (produto.nome.isEmpty || produto.predio.isEmpty || produto.quantidade <= 0) {
    final missingFields = [];
    if (produto.nome.isEmpty) missingFields.add('nome');
    if (produto.predio.isEmpty) missingFields.add('predio');
    if (produto.quantidade <= 0) missingFields.add('quantidade');

    _logger.severe('Erro: Dados inválidos para o produto. Campos obrigatórios ausentes: ${missingFields.join(', ')}.');
    return false;
  }

  final url = Uri.parse('$apiUrl/produtos');
  try {
    // Ensure categoriaId and nomeCategoria are handled correctly
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': produto.nome,
        'condicao': produto.condicao,
        'predio': produto.predio,
        'quantidade': produto.quantidade,
        'criado_em': produto.criadoEm.toIso8601String(),
        'categoria_id': produto.categoriaId,
        'nome_categoria': produto.nomeCategoria,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      _logger.severe('Erro ao criar produto: Código de status ${response.statusCode}, Resposta: ${response.body}');
      return false;
    }
  } catch (e) {
    _logger.severe('Exceção ao criar produto: $e');
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

Future<bool> updateProduto(Produto produto) async {
  throw Exception('Função desativada devido à remoção de id');
}
