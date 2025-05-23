class Produto {
  final String id;
  final String nome;
  final String condicao;
  final int quantidade;
  final DateTime criadoEm;
  final String? unidade;

  Produto({
    required this.id,
    required this.nome,
    required this.condicao,
    required this.quantidade,
    required this.criadoEm,
    this.unidade,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'].toString(),
      nome: json['nome'] ?? '',
      condicao: json['condicao'] ?? '',
      quantidade: int.tryParse(json['quantidade'].toString()) ?? 0,
      criadoEm: DateTime.parse(json['data_criacao'] ?? DateTime.now().toIso8601String()),
      unidade: json['unidade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'condicao': condicao,
      'quantidade': quantidade,
      'data_criacao': criadoEm.toIso8601String(),
      'unidade': unidade,
    };
  }
}