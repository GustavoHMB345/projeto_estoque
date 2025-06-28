import 'categoria.dart';

class Produto {
  final String id;
  final String nome;
  final String condicao;
  final int quantidade;
  final DateTime criadoEm;
  final String? categoriaId;

  Produto({
    required this.id,
    required this.nome,
    required this.condicao,
    required this.quantidade,
    required this.criadoEm,
    this.categoriaId,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'].toString(),
      nome: json['nome'] ?? '',
      condicao: json['condicao'] ?? '',
      quantidade: int.tryParse(json['quantidade'].toString()) ?? 0,
      criadoEm: DateTime.parse(json['data_criacao'] ?? DateTime.now().toIso8601String()),
      categoriaId: json['categoria_id']?.toString(), // Garante que o categoria_id seja sempre uma String ou null
    );
  }

  Map<String, dynamic> toJson({bool includeDataCriacao = true}) {
    return {
      'id': id,
      'nome': nome,
      'condicao': condicao,
      'quantidade': quantidade,
      'categoria_id': categoriaId, // Corrigido para usar o nome da nova coluna do banco
      if (includeDataCriacao) 'data_criacao': criadoEm.toIso8601String(),
    };
  }
}