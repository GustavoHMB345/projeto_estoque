class Produto {
  final String id;
  final String nome;
  final String categoriaId;
  final String condicao;
  final String unidade;
  final int quantidade;
  final DateTime criadoEm;

  Produto({
    required this.id,
    required this.nome,
    required this.categoriaId,
    required this.condicao,
    required this.unidade,
    required this.quantidade,
    required this.criadoEm,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['nome'] == null || json['categoria_id'] == null || json['condicao'] == null || json['unidade'] == null) {
      throw ArgumentError('Campos obrigatórios ausentes no JSON: id, nome, categoria_id, condicao ou unidade.');
    }

    return Produto(
      id: json['id'].toString(),
      nome: json['nome'] ?? '',
      categoriaId: json['categoria_id'].toString(),
      condicao: json['condicao'] ?? '',
      unidade: json['unidade'] ?? '',
      quantidade: json['quantidade'] != null ? int.tryParse(json['quantidade'].toString()) ?? (throw ArgumentError('Quantidade inválida no JSON.')) : 0,
      criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em']) ?? (throw ArgumentError('Formato de data inválido para criado_em.')) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'categoria_id': categoriaId,
      'condicao': condicao,
      'unidade': unidade,
      'quantidade': quantidade,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}