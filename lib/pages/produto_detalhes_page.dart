import 'package:flutter/material.dart';
import '../consumer_api.dart';
import '../models/produto.dart';
import '../models/tecnico.dart';
import '../models/setor.dart';
import '../models/historico_produto.dart';

class ProdutoDetalhesPage extends StatefulWidget {
  final Produto produto;
  final Future<void> Function(Produto)? onProdutoEditado;

  const ProdutoDetalhesPage({super.key, required this.produto, this.onProdutoEditado});

  @override
  ProdutoDetalhesPageState createState() => ProdutoDetalhesPageState();
}

class ProdutoDetalhesPageState extends State<ProdutoDetalhesPage> {
  late Produto produto;
  List<HistoricoProduto> _historico = [];

  @override
  void initState() {
    super.initState();
    produto = widget.produto;
    _carregarProdutoAtualizado();
    _carregarHistorico();
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

  Future<void> _carregarHistorico() async {
    try {
      final historico = await fetchHistoricoProduto(int.parse(produto.id.toString()));
      if (!mounted) return;
      setState(() {
        _historico = historico.map((item) => HistoricoProduto.fromJson(item)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar histórico: $e')),
      );
    }
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
              onPressed: () async {
                final atualizado = Produto(
                  id: produto.id,
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                  criadoEm: produto.criadoEm,
                );
                // Chama a API para atualizar o produto
                bool ok = false;
                if (widget.onProdutoEditado != null) {
                  // Se vier da tela principal, já faz update lá
                  await widget.onProdutoEditado!(atualizado);
                  ok = true;
                } else {
                  // Atualiza diretamente aqui se não vier callback
                  ok = await updateItem('produtos', atualizado.id, atualizado.toJson(includeDataCriacao: false));
                  if (ok) {
                    // Cria o primeiro histórico do produto
                    await createItem('historico', {
                      'idProduto': atualizado.id,
                      'campo': 'criação',
                      'valor_antigo': 'N/A',
                      'valor_novo': 'Produto criado',
                      'tecnico': 'Sistema',
                      'setor': 'Inicial'
                    });
                  } else {
                    debugPrint('Erro ao atualizar o produto diretamente no backend.');
                  }
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Produto atualizado!' : 'Erro ao atualizar produto!')),
                );
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
                  return Text('Erro ao carregar produto atualizado: \\${snapshot.error}');
                } else if (snapshot.hasData) {
                  final produtoAtualizado = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nome: \\${produtoAtualizado.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Condição: \\${produtoAtualizado.condicao}'),
                      Text('Quantidade: \\${produtoAtualizado.quantidade}'),
                      Text('Criado em: \\${produtoAtualizado.criadoEm.toLocal().day.toString().padLeft(2, '0')}-'
                          '\\${produtoAtualizado.criadoEm.toLocal().month.toString().padLeft(2, '0')}-'
                          '\\${produtoAtualizado.criadoEm.toLocal().year.toString().substring(2)}'),
                      const SizedBox(height: 24),
                      Text('Histórico de Edições:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      _historico.isEmpty
                          ? const Text('Nenhuma edição registrada.')
                          : SizedBox(
                              height: 120,
                              child: ListView.builder(
                                itemCount: _historico.length,
                                itemBuilder: (context, idx) {
                                  final h = _historico[idx];
                                  return ListTile(
                                    title: Text('${h.campo}: ${h.valorAntigo} -> ${h.valorNovo}'),
                                    subtitle: Text('Técnico: ${h.tecnico} | Setor: ${h.setor}'),
                                    trailing: Text(
                                      '${h.dataAlteracao.day.toString().padLeft(2, '0')}/'
                                      '${h.dataAlteracao.month.toString().padLeft(2, '0')}/'
                                      '${h.dataAlteracao.year.toString().substring(2)}',
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  );
                } else {
                  return const Text('Produto não encontrado');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}