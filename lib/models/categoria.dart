class Categoria {
  final String id;
  final String nome;

  Categoria({required this.id, required this.nome});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'nome': nome};
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
