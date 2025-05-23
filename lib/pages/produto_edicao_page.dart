import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../consumer_api.dart';
// Importa a lógica da API

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
  late TextEditingController _predioController;
  late TextEditingController _quantidadeController;
  late TextEditingController _dataCriacaoController;
  late TextEditingController _unidadeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _categoriaController = TextEditingController(text: widget.produto.categoriaId);
    _condicaoController = TextEditingController(text: widget.produto.condicao);
    _predioController = TextEditingController(text: widget.produto.predio);
    _quantidadeController = TextEditingController(text: widget.produto.quantidade.toString());
    _dataCriacaoController = TextEditingController(text: widget.produto.criadoEm.toIso8601String());
    _unidadeController = TextEditingController(text: widget.produto.unidade);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _condicaoController.dispose();
    _predioController.dispose();
    _quantidadeController.dispose();
    _dataCriacaoController.dispose();
    _unidadeController.dispose();
    super.dispose();
  }

  Future<void> _criarProduto() async {
    // Se for categoria, só envia nomeCategoria e não chama fetchCategorias
    final isCategoria = _nomeController.text.isEmpty && _predioController.text.isEmpty && _unidadeController.text.isEmpty && (_quantidadeController.text.isEmpty || int.tryParse(_quantidadeController.text) == 0);

    if (isCategoria) {
      // Chama diretamente o endpoint de categoria
      final response = await createCategoria(_categoriaController.text);
      if (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria criada com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar a categoria. Verifique os detalhes no log.')),
        );
      }
      return;
    }

    // Produto normal
    final novoProduto = Produto(
      nome: _nomeController.text,
      condicao: _condicaoController.text,
      predio: _predioController.text,
      unidade: _unidadeController.text,
      quantidade: int.tryParse(_quantidadeController.text.trim()) ?? 0,
      criadoEm: DateTime.tryParse(_dataCriacaoController.text.trim()) ?? DateTime.now(),
      categoriaId: '',
      nomeCategoria: _categoriaController.text,
    );

    try {
      final response = await createProduto(novoProduto);
      if (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto criado com sucesso!')),
        );
        Navigator.pop(context, novoProduto);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar o produto. Verifique os detalhes no log.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      debugPrint('Erro ao criar produto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Produto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _criarProduto,
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
              decoration: const InputDecoration(labelText: 'Categoria (ID ou Nome)'),
              keyboardType: TextInputType.text, // Permitir texto para alinhar com a model
            ),
            DropdownButtonFormField<String>(
              value: _condicaoController.text,
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
              controller: _predioController,
              decoration: const InputDecoration(labelText: 'Predio'),
            ),
            TextField(
              controller: _quantidadeController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (int.tryParse(value) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quantidade deve ser um número inteiro válido.')),
                  );
                }
              },
            ),
            TextField(
              controller: _dataCriacaoController,
              decoration: const InputDecoration(labelText: 'Data de Criação (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
              onChanged: (value) {
                if (DateTime.tryParse(value) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data de criação deve estar no formato YYYY-MM-DD.')),
                  );
                }
              },
            ),
            TextField(
              controller: _unidadeController,
              decoration: const InputDecoration(labelText: 'Unidade'),
            ),
          ],
        ),
      ),
    );
  }
}
