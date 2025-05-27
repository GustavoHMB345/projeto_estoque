import 'package:flutter/material.dart';
import '../consumer_api.dart';
import '../models/produto.dart';

class ProdutoDetalhesPage extends StatefulWidget {
  final Produto produto;
  final Future<void> Function(Produto)? onProdutoEditado;

  const ProdutoDetalhesPage({super.key, required this.produto, this.onProdutoEditado});

  @override
  ProdutoDetalhesPageState createState() => ProdutoDetalhesPageState();
}

class ProdutoDetalhesPageState extends State<ProdutoDetalhesPage> {
  late Produto produto;
  final List<String> _historico = [];

  @override
  void initState() {
    super.initState();
    produto = widget.produto;
    _carregarProdutoAtualizado();
  }

  Future<Produto> fetchProdutoAtualizado() async {
    // Simulate fetching updated product details from the database
    await Future.delayed(const Duration(milliseconds: 1));
    return produto; // Replace with actual database fetch logic
  }

  void _carregarProdutoAtualizado() async {
    try {
      final produtoAtualizado = await fetchProdutoAtualizado();
      if (!mounted) return;
      setState(() {
        produto = produtoAtualizado;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto atualizado: $e')),
      );
    }
  }

  void _adicionarAoHistorico(String acao) {
    final agora = DateTime.now();
    final dataHora = "${agora.day.toString().padLeft(2, '0')}/"
        "${agora.month.toString().padLeft(2, '0')}/"
        "${agora.year} - "
        "${agora.hour.toString().padLeft(2, '0')}: "
        "${agora.minute.toString().padLeft(2, '0')}";
    setState(() {
      _historico.add("$dataHora: $acao");
    });
  }

  Future<void> _editarProdutoDialog() async {
    final nomeController = TextEditingController(text: produto.nome);
    final quantidadeController = TextEditingController(text: produto.quantidade.toString());
    final condicaoController = TextEditingController(text: produto.condicao);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome do Produto'),
                ),
                TextField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: condicaoController.text,
                  items: const [
                    DropdownMenuItem(value: 'novo', child: Text('Novo')),
                    DropdownMenuItem(value: 'usado', child: Text('Usado')),
                  ],
                  onChanged: (value) => condicaoController.text = value ?? 'novo',
                  decoration: const InputDecoration(labelText: 'Condição'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final atualizado = Produto(
                  id: produto.id,
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                  criadoEm: produto.criadoEm,
                );
                _adicionarAoHistorico("Produto editado: Nome: ${atualizado.nome}, Condição: ${atualizado.condicao}, Quantidade: ${atualizado.quantidade}");
                setState(() {
                  produto = atualizado;
                });
                Navigator.pop(context);
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(produto.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarProdutoDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Produto>(
              future: fetchProdutoAtualizado(),
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
                      Text('Condição: ${produtoAtualizado.condicao}'),
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
            const SizedBox(height: 16),
            const Text('Histórico de Edição e Movimentação:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _historico.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_historico[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}