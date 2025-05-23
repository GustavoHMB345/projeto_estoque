class Tecnico {
  final String id;
  final String nome;
  final String email;

  Tecnico({required this.id, required this.nome, required this.email});

  factory Tecnico.fromJson(Map<String, dynamic> json) {
    return Tecnico(
      id: json['idTecnico'].toString(),
      nome: json['nomeTecnico'] ?? '',
      email: json['emailTecnico'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTecnico': id,
      'nomeTecnico': nome,
      'emailTecnico': email,
    };
  }
}