import 'package:flutter/material.dart';
import '../consumer_api.dart' as api; // ADICIONADO: Import da API
import '../models/movimentacao.dart';
import '../models/produto.dart';
import 'package:intl/intl.dart';

class ProdutoDetalhesPage extends StatefulWidget {
  final Produto produto;
  // ADICIONADO: Callback para notificar a tela anterior sobre a edição
  final Future<void> Function(Produto produtoEditado)? onProdutoEditado;

  const ProdutoDetalhesPage({
    super.key,
    required this.produto,
    this.onProdutoEditado,
  });

  @override
  ProdutoDetalhesPageState createState() => ProdutoDetalhesPageState();
}

class ProdutoDetalhesPageState extends State<ProdutoDetalhesPage> {
  late Produto produto;
  late Future<List<Movimentacao>> _movimentacoesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    produto = widget.produto;
    _carregarMovimentacoes();
  }

  void _carregarMovimentacoes() {
    setState(() {
      _movimentacoesFuture = api.fetchMovimentacoesPorProduto(produto.id);
    });
  }

  Future<void> _editarProdutoDialog() async {
    final nomeController = TextEditingController(text: produto.nome);
    final quantidadeController = TextEditingController(text: produto.quantidade.toString());
    final condicaoController = TextEditingController(text: produto.condicao);
    final produtoAntigo = produto;

    final bool? salvar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar Alterações'),
            ),
          ],
        );
      },
    );

    if (salvar == true) {
      setState(() => _isLoading = true);
      try {
        final atualizado = Produto(
          id: produto.id,
          nome: nomeController.text.trim(),
          condicao: condicaoController.text,
          quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
          criadoEm: produto.criadoEm,
          categoriaId: produto.categoriaId,
        );

        // CORREÇÃO: Chamada à API para salvar as alterações
        final success = await api.updateItem('produtos', produto.id, atualizado.toJson(includeDataCriacao: false));
        
        if (!mounted) return;

        if (success) {
          setState(() {
            produto = atualizado;
          });
          _carregarMovimentacoes();

          // Chama o callback para notificar a página anterior
          if (widget.onProdutoEditado != null) {
            await widget.onProdutoEditado!(atualizado);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao atualizar o produto na API.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(produto.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F3C34),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editarProdutoDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalhes do Produto', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF333333))),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nome: ${produto.nome}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Condição: ${produto.condicao}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Quantidade: ${produto.quantidade}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Criado em: ${produto.criadoEm.toLocal().toString().substring(0, 10)}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Histórico de Movimentações:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Movimentacao>>(
                    future: _movimentacoesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhum histórico de movimentação encontrado.'));
                      }

                      final movimentacoes = snapshot.data!;
                      return ListView.builder(
                        itemCount: movimentacoes.length,
                        itemBuilder: (context, index) {
                          final mov = movimentacoes[index];
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(mov.dataHora.toLocal());
                          final icon = mov.tipo == 'entrada'
                              ? const Icon(Icons.arrow_downward, color: Colors.green)
                              : mov.tipo == 'saida'
                                  ? const Icon(Icons.arrow_upward, color: Colors.red)
                                  : const Icon(Icons.edit, color: Colors.blue);
                          final title = 'Tipo: ${mov.tipo[0].toUpperCase()}${mov.tipo.substring(1)} | Qtd: ${mov.quantidade}';
                          final subtitle = '${mov.observacao ?? 'Sem observação.'}\nData: $formattedDate';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: icon,
                              title: Text(title),
                              subtitle: Text(subtitle),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}