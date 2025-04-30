class Produto {
  final String id;
  final String nome;
  final String categoriaId;
  final String condicao;
  final String unidade;
  final int quantidade;
  final double precoUnitario;
  final DateTime criadoEm;

  Produto({
    required this.id,
    required this.nome,
    required this.categoriaId,
    required this.condicao,
    required this.unidade,
    required this.quantidade,
    required this.precoUnitario,
    required this.criadoEm,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'].toString(), // Garantindo que o ID seja tratado como String
      nome: json['nome'] ?? '',
      categoriaId: json['categoria_id'].toString(), // Garantindo que o ID da categoria seja tratado como String
      condicao: json['condicao'] ?? '',
      unidade: json['unidade'] ?? '',
      quantidade: int.tryParse(json['quantidade'].toString()) ?? 0, // Garantindo que a quantidade seja tratada como int
      precoUnitario: double.tryParse(json['preco_unitario'].toString()) ?? 0.0, // Garantindo que o preço unitário seja tratado como double
      criadoEm: DateTime.parse(json['criado_em'] ?? DateTime.now().toIso8601String()),
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
      'preco_unitario': precoUnitario,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}