class Sala {
  final String id;
  final String nome;

  Sala({required this.id, required this.nome});

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      id: json['idSala'].toString(),
      nome: json['nomeSala'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSala': id,
      'nomeSala': nome,
    };
  }
}