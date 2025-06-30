import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import 'models/movimentacao.dart';

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
    print('fetchDados($endpoint) status: \\${response.statusCode}');
    print('fetchDados($endpoint) body: \\${response.body}');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro \\${response.statusCode}: \\${response.reasonPhrase}');
    }
  } catch (e) {
    _logger.severe('Erro na requisição: $e');
    throw Exception('Erro ao conectar ao servidor: $e');
  } finally {
    client.close();
  }
}

Future<dynamic> createItem(String endpoint, Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/$endpoint'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode == 201) {
    return true; // Sucesso na criação
  } else {
    // Tentar decodificar o corpo da resposta
    String responseBodyString = response.body;
    dynamic decodedBody;
    try {
      decodedBody = jsonDecode(responseBodyString);
    } catch (e) {
      // Corpo não é JSON válido ou está vazio
      return {'error': 'Erro na API (${response.statusCode}): ${response.reasonPhrase}. Resposta não é JSON ou está vazia.'};
    }

    if (decodedBody is Map<String, dynamic>) {
      // Se já tem 'message' ou 'error', retorna como está
      if (decodedBody.containsKey('message') || decodedBody.containsKey('error')) {
        return decodedBody;
      } else {
        // Se é um Map mas não tem as chaves esperadas, tenta pegar algum detalhe ou retorna genérico
        // Pega a representação string do Map como fallback para a mensagem de erro
        String detail = decodedBody.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        return {'error': 'Erro da API (${response.statusCode}): $detail'};
      }
    } else if (decodedBody is String && decodedBody.isNotEmpty) {
        // Se o corpo decodificado for uma string (ex: mensagem de erro simples da API)
        return {'error': 'Erro da API (${response.statusCode}): $decodedBody'};
    }
    else {
      // Se o corpo decodificado não for um Map nem uma String útil, ou for uma lista, etc.
      String bodyPreview = responseBodyString.length > 100 ? '${responseBodyString.substring(0, 100)}...' : responseBodyString;
      return {'error': 'Erro na API (${response.statusCode}): ${response.reasonPhrase}. Resposta da API: $bodyPreview'};
    }
  }
}

Future<bool> updateItem(String endpoint, String id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse('$apiBaseUrl/$endpoint/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  debugPrint('PUT $apiBaseUrl/$endpoint/$id => ${response.statusCode} ${response.body}');
  return response.statusCode == 200;
}

Future<bool> deleteItem(String endpoint, String id) async {
  final response = await http.delete(
    Uri.parse('$apiBaseUrl/$endpoint/$id'),
  );
  // Log para depuração
  debugPrint('DELETE $apiBaseUrl/$endpoint/$id => ${response.statusCode} ${response.body}');
  // Considere sucesso se for 200 (OK) ou 204 (No Content)
  if (response.statusCode == 200 || response.statusCode == 204) {
    return true;
  } else {
    // Opcional: lançar exceção para capturar no app
    throw Exception('Erro ao excluir: ${response.statusCode} ${response.body}');
  }
}

Future<List<Movimentacao>> fetchMovimentacoesPorProduto(String produtoId) async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/movimentacoes/produto/$produtoId'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((json) => Movimentacao.fromJson(json)).toList();
  } else {
    throw Exception('Falha ao carregar movimentações do produto');
  }
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

Future<bool> createMovimentacao(Map<String, dynamic> movimentacao) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/movimentacoes'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(movimentacao),
  );
  return response.statusCode == 201;
}

Future<int> fetchMovimentacoesHoje() async {
  final hoje = DateTime.now();
  final data = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
  final response = await http.get(
    Uri.parse('$apiBaseUrl/movimentacoes?data=$data'),
  );
  if (response.statusCode == 200) {
    final list = jsonDecode(response.body) as List;
    return list.length;
  }
  return 0;
}

// Funções genéricas para CRUD já estão corretas, não precisa alterar.
