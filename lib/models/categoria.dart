class Categoria {
  final String nome;
  final String? descricao;

  Categoria({required this.nome, this.descricao});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
    };
  }
}