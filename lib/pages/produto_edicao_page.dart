import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../consumer_api.dart'; // Import the API logic

class ProdutoEdicaoPage extends StatefulWidget {
  final Produto produto;

  const ProdutoEdicaoPage({super.key, required this.produto});

  @override
  ProdutoEdicaoPageState createState() => ProdutoEdicaoPageState();
}

class ProdutoEdicaoPageState extends State<ProdutoEdicaoPage> {
  late TextEditingController _nomeController;
  late TextEditingController _categoriaController;
  late TextEditingController _condicaoController;
  late TextEditingController _unidadeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _dataCriacaoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _categoriaController = TextEditingController(text: widget.produto.categoriaId);
    _condicaoController = TextEditingController(text: widget.produto.condicao);
    _unidadeController = TextEditingController(text: widget.produto.unidade);
    _quantidadeController = TextEditingController(text: widget.produto.quantidade.toString());
    _dataCriacaoController = TextEditingController(
      text: widget.produto.criadoEm.toLocal().toString().split(' ')[0],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _condicaoController.dispose();
    _unidadeController.dispose();
    _quantidadeController.dispose();
    _dataCriacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    final produtoAtualizado = Produto(
      id: widget.produto.id,
      nome: _nomeController.text,
      categoriaId: _categoriaController.text,
      condicao: _condicaoController.text,
      unidade: _unidadeController.text,
      quantidade: int.parse(_quantidadeController.text),
      criadoEm: DateTime.parse(_dataCriacaoController.text),
    );

    try {
      // Call the API to save the product
      final response = await updateProduto(produtoAtualizado);

      if (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
        Navigator.pop(context, produtoAtualizado);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar o produto. Verifique os detalhes no log.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      debugPrint('Erro ao salvar alterações: $e'); // Log error details
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarAlteracoes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _categoriaController,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            DropdownButtonFormField<String>(
              value: _condicaoController.text.isNotEmpty ? _condicaoController.text : 'novo',
              items: const [
                DropdownMenuItem(value: 'novo', child: Text('Novo')),
                DropdownMenuItem(value: 'usado', child: Text('Usado')),
              ],
              onChanged: (value) {
                setState(() {
                  _condicaoController.text = value ?? 'novo';
                });
              },
              decoration: const InputDecoration(labelText: 'Condição'),
            ),
            TextField(
              controller: _unidadeController,
              decoration: const InputDecoration(labelText: 'Unidade'),
            ),
            TextField(
              controller: _quantidadeController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _dataCriacaoController,
              decoration: const InputDecoration(labelText: 'Data de Criação (DD-MM-YY)'),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
      ),
    );
  }
}