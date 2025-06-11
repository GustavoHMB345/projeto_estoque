import 'package:flutter/material.dart';
import 'package:projeto_estoque/pages/produto_detalhes_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import '../consumer_api.dart';
import '../models/produto.dart';
import 'package:logging/logging.dart';
import 'dart:async'; // Importar para usar Timer

import 'usuarios_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _textController = TextEditingController();
  late AppState _appState;
  final _logger = Logger('MyHomePage');
  Timer? _debounce; // Adicionar um Timer para o debounce

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = Provider.of<AppState>(context, listen: false);
    _appState.addListener(_updateDataFromApi);
    _updateDataFromApi();
  }

  @override
  void dispose() {
    _appState.removeListener(_updateDataFromApi);
    _textController.dispose();
    _debounce?.cancel(); // Cancelar o timer no dispose
    super.dispose();
  }

  void _updateDataFromApi() {
    setState(() {
      // Força a reconstrução da UI quando os dados da API são atualizados via AppState
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        // A lista de produtos será filtrada no FutureBuilder, não precisa de fetch aqui
      });
    });
  }

  Future<void> _adicionarProduto() async {
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final condicaoController = TextEditingController(text: 'novo');

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Produto'),
          content: Column(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final produto = Produto(
                  id: '',
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                  criadoEm: DateTime.now(),
                );
                final response = await createItem('produtos', produto.toJson());
                if (!mounted) return;
                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto criado com sucesso!')),
                  );
                  Navigator.pop(context);
                  // Registrar movimentação de entrada
                  final authModel = Provider.of<AuthModel>(context, listen: false);
                  await createMovimentacao({
                    'produto_id': produto.id, // O ID do produto recém-criado pode não ser retornado pela API, verificar
                    'tipo': 'entrada',
                    'quantidade': produto.quantidade,
                    'usuario_id': authModel.usuario?.id,
                    'data_hora': DateTime.now().toIso8601String(),
                    'observacao': 'Produto adicionado ao estoque',
                  });
                  _updateDataFromApi(); // Atualiza a dashboard e lista
                } else {
                  _logger.severe('Erro ao salvar o produto. Verifique os dados enviados e a conexão com a API.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao criar produto: Verifique os dados e tente novamente.')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarProduto(Produto produto) async {
    final nomeController = TextEditingController(text: produto.nome);
    final quantidadeController = TextEditingController(text: produto.quantidade.toString());
    final condicaoController = TextEditingController(text: produto.condicao);
    final quantidadeAntiga = produto.quantidade; // Salva a quantidade antiga

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Produto'),
          content: Column(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final novaQuantidade = int.tryParse(quantidadeController.text.trim()) ?? 0;
                final atualizado = Produto(
                  id: produto.id,
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  quantidade: novaQuantidade,
                  criadoEm: produto.criadoEm,
                );
                final response = await updateItem('produtos', produto.id, atualizado.toJson(includeDataCriacao: false));
                if (!mounted) return;
                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto atualizado com sucesso!')),
                  );
                  Navigator.pop(context);
                  // Registrar movimentação de edição/ajuste
                  final authModel = Provider.of<AuthModel>(context, listen: false);
                  if (novaQuantidade != quantidadeAntiga) {
                    final tipoMov = novaQuantidade > quantidadeAntiga ? 'entrada' : 'saida';
                    final qtdMov = (novaQuantidade - quantidadeAntiga).abs();
                    await createMovimentacao({
                      'produto_id': produto.id,
                      'tipo': tipoMov,
                      'quantidade': qtdMov,
                      'usuario_id': authModel.usuario?.id,
                      'data_hora': DateTime.now().toIso8601String(),
                      'observacao': 'Ajuste de quantidade por edição (de $quantidadeAntiga para $novaQuantidade)',
                    });
                  }
                  // Registrar edição geral (mesmo sem mudança de quantidade, mas com outros campos)
                  await createMovimentacao({
                    'produto_id': produto.id,
                    'tipo': 'edicao',
                    'quantidade': 0, // Não há mudança de quantidade líquida aqui
                    'usuario_id': authModel.usuario?.id,
                    'data_hora': DateTime.now().toIso8601String(),
                    'observacao': 'Detalhes do produto editados',
                  });
                  _updateDataFromApi(); // Atualiza a dashboard e lista
                } else {
                  _logger.severe('Erro ao atualizar o produto. Verifique os dados enviados e a conexão com a API.');
                  // ignore: avoid_print
                  print('[ERRO] Falha ao atualizar produto: ${atualizado.toJson()}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao atualizar produto: Verifique os dados e tente novamente.')),
                  );
                }
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _excluirProduto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await deleteItem('produtos', id);
      if (!mounted) return;
      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso!')),
        );
        // Registrar movimentação de exclusão
        final authModel = Provider.of<AuthModel>(context, listen: false);
        await createMovimentacao({
          'produto_id': id,
          'tipo': 'exclusao',
          'quantidade': 0, // Não há mudança de quantidade, apenas registro da exclusão
          'usuario_id': authModel.usuario?.id,
          'data_hora': DateTime.now().toIso8601String(),
          'observacao': 'Produto removido permanentemente do estoque',
        });
        _updateDataFromApi(); // Atualiza a dashboard e lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir produto. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext
      context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Conteúdo Principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDashboardSummaryCards(),
                        const SizedBox(height: 20),
                        _buildSearchAndFilterSection(),
                        const SizedBox(height: 20),
                        _buildProductsTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final authModel = Provider.of<AuthModel>(context, listen: false);
    final emailUsuario = authModel.usuario?.email ?? 'email@exemplo.com';
    final nomeUsuario = authModel.usuario?.nome ?? 'Usuário';

    // Calcula o total de produtos e produtos em estoque baixo e total de categorias únicas
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchDados('produtos'),
      builder: (context, snapshot) {
        int totalProdutos = 0;
        int estoqueBaixo = 0;
        Set<String> categoriasUnicas = {};

        if (snapshot.hasData) {
          final produtos = snapshot.data?.map((json) => Produto.fromJson(json)).toList() ?? [];
          totalProdutos = produtos.length;
          estoqueBaixo = produtos.where((p) => p.quantidade <= 10).length;
          for (var p in produtos) {
            categoriasUnicas.add(p.condicao);
          }
        }
        int totalCategorias = categoriasUnicas.length;

        return Container(
          width: 250,
          color: const Color(0xFF4F3C34),
          child: Column(
            children: [
              // Header do Sidebar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                alignment: Alignment.center,
                child: const Text(
                  'EstoqueControl',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSidebarItem(Icons.dashboard, 'Dashboard', () {
                      // Já está na dashboard, nada a fazer
                    }),
                    _buildSidebarItem(Icons.inventory, 'Produtos', () {
                      // Nada a fazer, já está na seção de produtos/dashboard
                    }),
                    const Divider(color: Colors.white54),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo do Estoque',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryText('Total de Produtos: $totalProdutos'),
                          _buildSummaryText('Categorias: $totalCategorias'),
                          _buildSummaryText('Estoque Baixo: $estoqueBaixo', color: Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Parte inferior com informações do usuário e logout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF4F3C34)),
                      ),
                      title: Text(nomeUsuario, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      subtitle: Text(emailUsuario, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text('Logout', style: TextStyle(color: Colors.white)),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Logout'),
                            content: const Text('Tem certeza que deseja sair?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sair'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          authModel.logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }

  Widget _buildSummaryText(String text, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authModel = Provider.of<AuthModel>(context, listen: false);
    final nomeUsuario = authModel.usuario?.nome ?? 'Usuário';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Olá, $nomeUsuario',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummaryCards() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchDados('produtos'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Erro ao carregar dados: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final produtos = snapshot.data?.map((json) => Produto.fromJson(json)).toList() ?? [];

          // Calcula os valores para os cards
          int totalEmEstoque = 0;
          int estoqueBaixo = 0;
          int movimentacoes = 0; // Vai ser preenchido pela API

          for (var p in produtos) {
            totalEmEstoque += p.quantidade;
            if (p.quantidade <= 10) {
              estoqueBaixo++;
            }
          }

          return FutureBuilder<int>(
            future: fetchMovimentacoesHoje(), // Buscar movimentações de hoje
            builder: (context, movSnapshot) {
              if (movSnapshot.connectionState == ConnectionState.waiting) {
                movimentacoes = 0; // Ou um valor temporário
              } else if (movSnapshot.hasData) {
                movimentacoes = movSnapshot.data!;
              } else if (movSnapshot.hasError) {
                _logger.severe('Erro ao carregar movimentações de hoje: ${movSnapshot.error}');
                movimentacoes = 0;
              }

              return GridView.count(
                crossAxisCount: 3, // Ajustado para 3 colunas, pois uma será removida
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSummaryCard(
                    context,
                    title: 'Total em Estoque',
                    value: totalEmEstoque.toString(),
                    icon: Icons.inventory_2,
                    trend: '5.3% desde o mês passado', // Manter como exemplo
                    iconBgColor: Colors.orange,
                  ),
                  // Card de 'Valor do Estoque' removido
                  _buildSummaryCard(
                    context,
                    title: 'Estoque Baixo',
                    value: estoqueBaixo.toString(),
                    icon: Icons.warning_amber,
                    trend: '3 itens a mais que ontem', // Manter como exemplo
                    iconBgColor: Colors.red,
                  ),
                  _buildSummaryCard(
                    context,
                    title: 'Movimentações',
                    value: movimentacoes.toString(),
                    icon: Icons.swap_vert,
                    trend: 'Hoje',
                    iconBgColor: Colors.green,
                  ),
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required String trend,
        required Color iconBgColor,
      }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconBgColor, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              trend,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Buscar Produtos...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            ),
            onChanged: _onSearchChanged, // Usar o novo método com debounce
          ),
        ),
        const SizedBox(width: 15),
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            ),
            value: 'Todas as categorias',
            items: const [
              DropdownMenuItem(value: 'Todas as categorias', child: Text('Todas as categorias')),
              // Adicionar categorias dinamicamente
            ],
            onChanged: (value) {
              // Lógica de filtro por categoria
            },
          ),
        ),
        const SizedBox(width: 15),
        ElevatedButton.icon(
          onPressed: _adicionarProduto,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE67700),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Novo Produto'),
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produtos em Estoque',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 15),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchDados('produtos'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar produtos: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  final produtos = snapshot.data?.map((json) => Produto.fromJson(json)).toList() ?? [];
                  // Filtra os produtos com base na busca
                  final filteredProdutos = produtos.where((p) {
                    if (_textController.text.isEmpty) {
                      return true;
                    }
                    return p.nome.toLowerCase().contains(_textController.text.toLowerCase());
                  }).toList();

                  if (filteredProdutos.isEmpty) {
                    return const Center(child: Text('Nenhum produto encontrado.'));
                  }

                  // Cabeçalho da tabela
                  final List<DataColumn> columns = [
                    const DataColumn(label: Text('PRODUTO', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('CATEGORIA', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('QUANTIDADE', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('AÇÕES', style: TextStyle(fontWeight: FontWeight.bold))),
                  ];

                  // Linhas da tabela
                  final List<DataRow> rows = filteredProdutos.map((produto) {
                    // Correção para RangeError: garante que o ID tenha pelo menos 8 caracteres
                    String sku = produto.id.length >= 8 ? produto.id.substring(0, 8) : produto.id;

                    return DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('SKU: $sku', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )),
                      DataCell(Text(produto.condicao == 'novo' ? 'Eletrônicos' : 'Periféricos')),
                      DataCell(Text(produto.quantidade.toString())),
                      DataCell(_buildStatusChip(produto.quantidade)),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _editarProduto(produto),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                            child: const Text('Editar'),
                          ),
                          TextButton(
                            onPressed: () => _excluirProduto(produto.id),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Excluir'),
                          ),
                        ],
                      )),
                    ]);
                  }).toList();

                  return SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: columns,
                      rows: rows,
                      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                      dataRowColor: MaterialStateProperty.all(Colors.white),
                      border: TableBorder.all(color: Colors.grey[200]!),
                      columnSpacing: 30,
                      horizontalMargin: 10,
                      headingRowHeight: 50,
                      dataRowHeight: 70,
                      showCheckboxColumn: false,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(int quantidade) {
    Color color;
    String text;
    if (quantidade > 10) {
      color = Colors.green[100]!;
      text = 'Em estoque';
    } else if (quantidade > 0) {
      color = Colors.orange[100]!;
      text = 'Estoque baixo';
    } else {
      color = Colors.red[100]!;
      text = 'Sem estoque';
    }

    Color textColor;
    if (text == 'Em estoque') {
      textColor = Colors.green[800]!;
    } else if (text == 'Estoque baixo') {
      textColor = Colors.orange[800]!;
    } else {
      textColor = Colors.red[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}