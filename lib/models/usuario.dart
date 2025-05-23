class Usuario {
  final String id;
  final String nome;
  final String email;
  final String login;
  final String senha;
  final String situacao;
  final String idSetor;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.login,
    required this.senha,
    required this.situacao,
    required this.idSetor,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['idUsuario'].toString(),
      nome: json['nomeUsuario'] ?? '',
      email: json['emailUsuario'] ?? '',
      login: json['loginUsuario'] ?? '',
      senha: json['senhaUsuario'] ?? '',
      situacao: json['situacaoUsuario'] ?? '',
      idSetor: json['idSetor_fk'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUsuario': id,
      'nomeUsuario': nome,
      'emailUsuario': email,
      'loginUsuario': login,
      'senhaUsuario': senha,
      'situacaoUsuario': situacao,
      'idSetor_fk': idSetor,
    };
  }
}