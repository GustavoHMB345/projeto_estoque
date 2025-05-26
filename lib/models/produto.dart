class Produto {
  final String id;
  final String nome;
  final String condicao;
  final int quantidade;
  final DateTime criadoEm;

  Produto({
    required this.id,
    required this.nome,
    required this.condicao,
    required this.quantidade,
    required this.criadoEm,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'].toString(),
      nome: json['nome'] ?? '',
      condicao: json['condicao'] ?? '',
      quantidade: int.tryParse(json['quantidade'].toString()) ?? 0,
      criadoEm: DateTime.parse(json['data_criacao'] ?? DateTime.now().toIso8601String()),
      
    );
  }

  Map<String, dynamic> toJson({bool includeDataCriacao = true}) {
    final map = {
      'id': id,
      'nome': nome,
      'condicao': condicao,
      'quantidade': quantidade,
    };
    if (includeDataCriacao) {
      map['data_criacao'] = criadoEm.toIso8601String();
    }
    return map;
  }
}