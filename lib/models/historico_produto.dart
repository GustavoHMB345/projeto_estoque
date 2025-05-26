class HistoricoProduto {
  final int id;
  final int idProduto;
  final String campo;
  final String valorAntigo;
  final String valorNovo;
  final String tecnico;
  final String setor;
  final DateTime dataAlteracao;

  HistoricoProduto({
    required this.id,
    required this.idProduto,
    required this.campo,
    required this.valorAntigo,
    required this.valorNovo,
    required this.tecnico,
    required this.setor,
    required this.dataAlteracao,
  });

  factory HistoricoProduto.fromJson(Map<String, dynamic> json) {
    return HistoricoProduto(
      id: json['id'],
      idProduto: json['idProduto'],
      campo: json['campo'],
      valorAntigo: json['valor_antigo'],
      valorNovo: json['valor_novo'],
      tecnico: json['tecnico'],
      setor: json['setor'],
      dataAlteracao: DateTime.parse(json['data_alteracao']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idProduto': idProduto,
      'campo': campo,
      'valor_antigo': valorAntigo,
      'valor_novo': valorNovo,
      'tecnico': tecnico,
      'setor': setor,
      'data_alteracao': dataAlteracao.toIso8601String(),
    };
  }
}
