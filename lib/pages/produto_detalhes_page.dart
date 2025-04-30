import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'produto_edicao_page.dart';

class ProdutoDetalhesPage extends StatelessWidget {
  final Produto produto;

  const ProdutoDetalhesPage({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(produto.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProdutoEdicaoPage(produto: produto),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${produto.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Categoria: ${produto.categoriaId}'),
            Text('Condição: ${produto.condicao}'),
            Text('Unidade: ${produto.unidade}'),
            Text('Quantidade: ${produto.quantidade}'),
            Text('Preço Unitário: R\$ ${produto.precoUnitario.toStringAsFixed(2)}'),
            Text('Criado em: ${produto.criadoEm.toLocal()}'),
          ],
        ),
      ),
    );
  }
}