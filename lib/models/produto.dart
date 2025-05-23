class Produto {
  final String nome;
  final String condicao;
  final String predio;
  final String unidade;
  final int quantidade;
  final DateTime criadoEm;
  final String categoriaId; // Renomeado para categoriaId para consistência
  final String nomeCategoria;

  Produto({
    required this.nome,
    required this.condicao,
    required this.predio,
    required this.unidade,
    required this.quantidade,
    required this.criadoEm,
    required this.categoriaId, // Atualizado para categoriaId
    required this.nomeCategoria,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'] ?? '',
      condicao: json['condicao'] ?? '',
      predio: json['predio'] ?? '',
      unidade: json['unidade'] ?? '',
      quantidade: int.tryParse(json['quantidade']?.toString() ?? '0') ?? 0,
      criadoEm: DateTime.tryParse(json['criado_em'] ?? '') ?? DateTime.now(),
      categoriaId: json['categoria_id']?.toString() ?? '', // Atualizado para categoriaId
      nomeCategoria: json['nome_categoria']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'condicao': condicao,
    'predio': predio,
    'unidade': unidade,
    'quantidade': quantidade,
    'criado_em': criadoEm.toIso8601String(),
    'categoria_id': categoriaId, // Atualizado para categoriaId
    'nome_categoria': nomeCategoria,
  };
}