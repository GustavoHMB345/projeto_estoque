class Setor {
  final String id;
  final String nome;

  Setor({required this.id, required this.nome});

  factory Setor.fromJson(Map<String, dynamic> json) {
    return Setor(
      id: json['idSetor'].toString(),
      nome: json['nomeSetor'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSetor': id,
      'nomeSetor': nome,
    };
  }
}