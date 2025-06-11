// lib/models/movimentacao.dart
class Movimentacao {
  final String id;
  final String produtoId;
  final String tipo;
  final int quantidade;
  final String? usuarioId; // Opcional
  final DateTime dataHora;
  final String? observacao; // Opcional

  Movimentacao({
    required this.id,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    this.usuarioId,
    required this.dataHora,
    this.observacao,
  });

  factory Movimentacao.fromJson(Map<String, dynamic> json) {
    return Movimentacao(
      id: json['id'] ?? '',
      produtoId: json['produto_id'] ?? json['productId'] ?? '', // Adapte se a API usar 'productId'
      tipo: json['tipo'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      usuarioId: json['usuario_id'] ?? json['userId'], // Adapte se a API usar 'userId'
      dataHora: DateTime.parse(json['data_hora'] ?? json['timestamp']), // Adapte o nome do campo da API
      observacao: json['observacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto_id': produtoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'usuario_id': usuarioId,
      'data_hora': dataHora.toIso8601String(),
      'observacao': observacao,
    };
  }
}