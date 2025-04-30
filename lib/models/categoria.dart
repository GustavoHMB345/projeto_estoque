class Categoria {
  final String id;
  final String nome;
  final String? descricao; // Adicionando o campo descricao

  Categoria({required this.id, required this.nome, this.descricao});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'].toString(), // Garantindo que o ID seja tratado como String
      nome: json['nome'] ?? '',
      descricao: json['descricao'], // Adicionando o mapeamento para descricao
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao, // Incluindo descricao no JSON
    };
  }
}