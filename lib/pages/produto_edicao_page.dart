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

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _categoriaController = TextEditingController(text: widget.produto.categoriaId);
    _condicaoController = TextEditingController(text: widget.produto.condicao);
    _predioController = TextEditingController(text: widget.produto.predio);
    _quantidadeController = TextEditingController(text: widget.produto.quantidade.toString());
    _dataCriacaoController = TextEditingController(text: widget.produto.criadoEm.toIso8601String());
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _condicaoController.dispose();
    _predioController.dispose();
    _quantidadeController.dispose();
    _dataCriacaoController.dispose();
    super.dispose();
  }

  Future<void> _criarProduto() async {
    // Updated to fetch and display the correct nomeCategoria
    final categorias = await fetchCategorias();
    final categoriaSelecionada = categorias.firstWhere(
      (cat) => cat['id'] == _categoriaController.text,
      orElse: () => {'nome_categoria': 'Desconhecido'},
    );

    final novoProduto = Produto(
      nome: _nomeController.text,
      condicao: _condicaoController.text,
      predio: _predioController.text,
      quantidade: int.tryParse(_quantidadeController.text.trim()) ?? 0,
      criadoEm: DateTime.tryParse(_dataCriacaoController.text.trim()) ?? DateTime.now(),
      categoriaId: _categoriaController.text,
      nomeCategoria: categoriaSelecionada['nome_categoria'],
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
      debugPrint('Erro ao criar produto: $e'); // Log detalhado do erro
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
          ],
        ),
      ),
    );
  }
}
