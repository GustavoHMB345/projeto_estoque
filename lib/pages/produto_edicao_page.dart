import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../consumer_api.dart';
// Importa a lógica da API

class ProdutoEdicaoPage extends StatefulWidget {
  const ProdutoEdicaoPage({super.key});

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
    _nomeController = TextEditingController();
    _categoriaController = TextEditingController();
    _condicaoController = TextEditingController(text: 'novo'); // valor padrão
    _unidadeController = TextEditingController();
    _quantidadeController = TextEditingController();
    _dataCriacaoController = TextEditingController();
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

  Future<void> _criarProduto() async {
    final novoProduto = Produto( // Garantindo que o ID seja um inteiro
      nome: _nomeController.text,
      categoriaId: _categoriaController.text.trim(), // Alterando categoriaId para aceitar String diretamente
      condicao: _condicaoController.text,
      unidade: _unidadeController.text,
      quantidade: int.tryParse(_quantidadeController.text.trim()) ?? 0, // Convertendo quantidade de String para int
      criadoEm: DateTime.tryParse(_dataCriacaoController.text.trim()) ?? DateTime.now(), id: '',
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
              controller: _unidadeController,
              decoration: const InputDecoration(labelText: 'Unidade'),
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
