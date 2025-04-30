class MovimentacaoEstoque {
  final String id;
  final String produtoId;
  final String tipo;
  final int quantidade;
  final DateTime dataMovimentacao;
  final String? observacao;

  MovimentacaoEstoque({
    required this.id,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    required this.dataMovimentacao,
    this.observacao,
  });

  factory MovimentacaoEstoque.fromJson(Map<String, dynamic> json) {
    return MovimentacaoEstoque(
      id: json['id'].toString(), // Garantindo que o ID seja tratado como String
      produtoId: json['produto_id'].toString(), // Garantindo que o ID do produto seja tratado como String
      tipo: json['tipo'] ?? '',
      quantidade: int.tryParse(json['quantidade'].toString()) ?? 0, // Garantindo que a quantidade seja tratada como int
      dataMovimentacao: DateTime.parse(json['data_movimentacao'] ?? DateTime.now().toIso8601String()),
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'data_movimentacao': dataMovimentacao.toIso8601String(),
      'observacao': observacao,
    };
  }
}