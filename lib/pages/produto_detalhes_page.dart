import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'produto_edicao_page.dart';

class ProdutoDetalhesPage extends StatefulWidget {
  final Produto produto;

  const ProdutoDetalhesPage({super.key, required this.produto});

  @override
  ProdutoDetalhesPageState createState() => ProdutoDetalhesPageState();
}

class ProdutoDetalhesPageState extends State<ProdutoDetalhesPage> {
  late Produto produto;

  @override
  void initState() {
    super.initState();
    produto = widget.produto;
    _carregarProdutoAtualizado();
  }

  Future<Produto> fetchProdutoAtualizado(String id) async {
    // Simulate fetching updated product details from the database
    await Future.delayed(const Duration(milliseconds: 1));
    return produto; // Replace with actual database fetch logic
  }

  void _carregarProdutoAtualizado() async {
    try {
      final produtoAtualizado = await fetchProdutoAtualizado(produto.id);
      if (!mounted) return; // Verifica se o widget ainda está montado
      setState(() {
        produto = produtoAtualizado;
      });
    } catch (e) {
      if (!mounted) return; // Verifica se o widget ainda está montado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto atualizado: $e')),
      );
    }
  }

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
                  builder: (context) => const ProdutoEdicaoPage(), // Removendo o parâmetro 'produto'
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Produto>(
          future: fetchProdutoAtualizado(produto.id.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Erro ao carregar produto atualizado: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final produtoAtualizado = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome: ${produtoAtualizado.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Categoria: ${produtoAtualizado.categoriaId}'),
                  Text('Condição: ${produtoAtualizado.condicao}'),
                  Text('Unidade: ${produtoAtualizado.unidade}'),
                  Text('Quantidade: ${produtoAtualizado.quantidade}'),
                  Text('Criado em: ${produtoAtualizado.criadoEm.toLocal().day.toString().padLeft(2, '0')}-'
                      '${produtoAtualizado.criadoEm.toLocal().month.toString().padLeft(2, '0')}-'
                      '${produtoAtualizado.criadoEm.toLocal().year.toString().substring(2)}'),
                ],
              );
            } else {
              return const Text('Produto não encontrado');
            }
          },
        ),
      ),
    );
  }
}