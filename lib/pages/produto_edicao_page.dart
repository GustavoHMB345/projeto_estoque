import 'package:flutter/material.dart';
import '../models/produto.dart';

class ProdutoEdicaoPage extends StatefulWidget {
  final Produto produto;

  const ProdutoEdicaoPage({super.key, required this.produto});

  @override
  _ProdutoEdicaoPageState createState() => _ProdutoEdicaoPageState();
}

class _ProdutoEdicaoPageState extends State<ProdutoEdicaoPage> {
  late TextEditingController _nomeController;
  late TextEditingController _categoriaController;
  late TextEditingController _condicaoController;
  late TextEditingController _unidadeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _precoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _categoriaController = TextEditingController(text: widget.produto.categoriaId);
    _condicaoController = TextEditingController(text: widget.produto.condicao);
    _unidadeController = TextEditingController(text: widget.produto.unidade);
    _quantidadeController = TextEditingController(text: widget.produto.quantidade.toString());
    _precoController = TextEditingController(text: widget.produto.precoUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _condicaoController.dispose();
    _unidadeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _salvarAlteracoes() {
    // Atualizar o produto com os novos valores
    final produtoAtualizado = Produto(
      id: widget.produto.id,
      nome: _nomeController.text,
      categoriaId: _categoriaController.text,
      condicao: _condicaoController.text,
      unidade: _unidadeController.text,
      quantidade: int.tryParse(_quantidadeController.text) ?? 0,
      precoUnitario: double.tryParse(_precoController.text) ?? 0.0,
      criadoEm: widget.produto.criadoEm,
    );

    // Aqui você pode adicionar a lógica para salvar o produto no banco de dados

    Navigator.pop(context, produtoAtualizado);
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
            TextField(
              controller: _condicaoController,
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
              controller: _precoController,
              decoration: const InputDecoration(labelText: 'Preço Unitário'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}