import 'package:flutter/material.dart';

class AparatoDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> aparato;

  const AparatoDetalhesPage({Key? key, required this.aparato}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Aparato: ${aparato['equipamento'] ?? 'N/A'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${aparato['id'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Equipamento: ${aparato['equipamento'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Marca: ${aparato['marca'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Data de Aquisição: ${aparato['data_aquisicao'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Local da Compra: ${aparato['local_compra'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Setor: ${aparato['setor'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Prédio: ${aparato['predio'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Sala: ${aparato['sala'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Preço: ${aparato['preco'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
            Text('Observação: ${aparato['observacao'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}