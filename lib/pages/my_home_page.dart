import 'package:flutter/material.dart';
import 'package:projeto_estoque/pages/produto_detalhes_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import '../consumer_api.dart' as api; // CORREÇÃO: Importa o consumer_api com prefixo 'api'
import '../models/produto.dart';
import '../models/categoria.dart'; // Importa o modelo Categoria
import 'package:logging/logging.dart';
import 'dart:async';  
import 'usuarios_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // CORREÇÃO: Removido o 'State' duplicado aqui. Deve ser '_MyHomePageState()'
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _textController = TextEditingController();
  late AppState _appState;
  final _logger = Logger('MyHomePage');
  Timer? _debounce;

  List<Categoria> _categorias = [];
  bool _carregandoCategorias = true;
  String? _categoriaFiltroSelecionada; // Agora começa como null

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
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
    _debounce?.cancel();
    super.dispose();
  }

  void _updateDataFromApi() {
    if (!mounted) return;
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
    // Garante que as categorias estejam atualizadas antes de abrir o diálogo
    await _carregarCategorias();

    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final condicaoController = TextEditingController(text: 'novo');
    // Use sempre o estado local _categorias, que está atualizado
    final categorias = _categorias;
    String? categoriaSelecionada = categorias.isNotEmpty ? categorias.first.id : null;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Corrige valor inicial se categorias mudaram
            if (categorias.isNotEmpty && (categoriaSelecionada == null || !categorias.any((c) => c.id == categoriaSelecionada))) {
              categoriaSelecionada = categorias.first.id;
            }
            return AlertDialog(
              title: const Text('Adicionar Produto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome do Produto'),
                  ),
                  DropdownButtonFormField<String>(
                    value: categoriaSelecionada,
                    items: categorias.isNotEmpty
                        ? categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList()
                        : [const DropdownMenuItem(value: null, child: Text('Sem categorias'))],
                    onChanged: categorias.isNotEmpty
                        ? (value) {
                            setStateDialog(() {
                              categoriaSelecionada = value;
                            });
                          }
                        : null,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    isExpanded: true,
                    disabledHint: const Text('Cadastre uma categoria primeiro'),
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
                  onPressed: categorias.isEmpty
                      ? null
                      : () async {
                          final produto = Produto(
                            id: '',
                            nome: nomeController.text.trim(),
                            condicao: condicaoController.text,
                            quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                            criadoEm: DateTime.now(),
                            categoriaId: categoriaSelecionada,
                          );
                          final response = await api.createItem('produtos', produto.toJson());
                          if (!mounted) return;
                          if (response is Map) {
                            final map = response as Map;
                            if (map['id'] != null) {
                              final novoId = map['id'];
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Produto criado com sucesso!')),
                              );
                              Navigator.pop(context);
                              final authModel = Provider.of<AuthModel>(context, listen: false);
                              await api.createMovimentacao({
                                'produto_id': novoId,
                                'tipo': 'entrada',
                                'quantidade': produto.quantidade,
                                'usuario_id': authModel.usuario?.idUsuario,
                                'data_hora': DateTime.now().toIso8601String(),
                                'observacao': 'Produto adicionado ao estoque',
                              });
                              // ATUALIZE AMBAS AS LISTAS
                              await _appState.carregarProdutosDaApi();
                              await _carregarCategorias(); // <--- ADICIONADO
                            } else if (map['message'] != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao criar produto: [31m${map['message']}[0m')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao criar produto: Verifique os dados e tente novamente.')),
                              );
                            }
                          } else if (response == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Produto criado com sucesso!')),
                              );
                              Navigator.pop(context);
                              // ATUALIZE AMBAS AS LISTAS AQUI TAMBÉM
                              await _appState.carregarProdutosDaApi();
                              await _carregarCategorias(); // <--- ADICIONADO
                          } else {
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
      },
    );
  }

  Future<void> _editarProduto(Produto produto) async {
    final nomeController = TextEditingController(text: produto.nome);
    final quantidadeController = TextEditingController(text: produto.quantidade.toString());
    final condicaoController = TextEditingController(text: produto.condicao);
    final quantidadeAntiga = produto.quantidade;
    String? categoriaSelecionada = produto.categoriaId ?? (_categorias.isNotEmpty ? _categorias.first.id : null);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Corrige valor inicial se categorias mudaram
            if (_categorias.isNotEmpty && (categoriaSelecionada == null || !_categorias.any((c) => c.id == categoriaSelecionada))) {
              categoriaSelecionada = _categorias.first.id;
            }
            return AlertDialog(
              title: const Text('Editar Produto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome do Produto'),
                  ),
                  DropdownButtonFormField<String>(
                    value: categoriaSelecionada,
                    items: _categorias.isNotEmpty
                        ? _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList()
                        : [const DropdownMenuItem(value: null, child: Text('Sem categorias'))],
                    onChanged: _categorias.isNotEmpty
                        ? (value) {
                            setStateDialog(() {
                              categoriaSelecionada = value;
                            });
                          }
                        : null,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    isExpanded: true,
                    disabledHint: const Text('Cadastre uma categoria primeiro'),
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
                  onPressed: _categorias.isEmpty
                      ? null
                      : () async {
                          final novaQuantidade = int.tryParse(quantidadeController.text.trim()) ?? 0;
                          final atualizado = Produto(
                            id: produto.id,
                            nome: nomeController.text.trim(),
                            condicao: condicaoController.text,
                            quantidade: novaQuantidade,
                            criadoEm: produto.criadoEm,
                            categoriaId: categoriaSelecionada, // Corrigido: garantir que a categoria selecionada seja salva
                          );
                          final response = await api.updateItem('produtos', produto.id, atualizado.toJson(includeDataCriacao: false));
                          if (!mounted) return;
                          if (response) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Produto atualizado com sucesso!')),
                            );
                            Navigator.pop(context);
                            final authModel = Provider.of<AuthModel>(context, listen: false);
                            if (novaQuantidade != quantidadeAntiga) {
                              final tipoMov = novaQuantidade > quantidadeAntiga ? 'entrada' : 'saida';
                              final qtdMov = (novaQuantidade - quantidadeAntiga).abs();
                              await api.createMovimentacao({
                                'produto_id': produto.id,
                                'tipo': tipoMov,
                                'quantidade': qtdMov,
                                'usuario_id': authModel.usuario?.idUsuario,
                                'data_hora': DateTime.now().toIso8601String(),
                                'observacao': 'Ajuste de quantidade por edição (de $quantidadeAntiga para $novaQuantidade)',
                              });
                            }
                            await api.createMovimentacao({
                              'produto_id': produto.id,
                              'tipo': 'edicao',
                              'quantidade': 0,
                              'usuario_id': authModel.usuario?.idUsuario,
                              'data_hora': DateTime.now().toIso8601String(),
                              'observacao': 'Detalhes do produto editados',
                            });
                            await _appState.carregarProdutosDaApi();
                            await _carregarCategorias(); // Garante atualização da lista de categorias
                          } else {
                            _logger.severe('Erro ao atualizar o produto. Verifique os dados enviados e a conexão com a API.');
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
      try {
        // Registrar movimentação de exclusão ANTES de excluir o produto
        final authModel = Provider.of<AuthModel>(context, listen: false);
        await api.createMovimentacao({
          'produto_id': id,
          'tipo': 'exclusao',
          'quantidade': 0, // Não há mudança de quantidade, apenas registro da exclusão
          'usuario_id': authModel.usuario?.idUsuario, // Usar idUsuario
          'data_hora': DateTime.now().toIso8601String(),
          'observacao': 'Produto removido permanentemente do estoque',
        });

        final response = await api.deleteItem('produtos', id); // CORREÇÃO: Usar api.deleteItem
        if (!mounted) return;
        if (response) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso!')),
          );
          _updateDataFromApi(); // Atualiza a dashboard e lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir produto. Tente novamente.')),
          );
        }
      } catch (e) {
        String msg = e.toString();
        if (msg.contains('404') && msg.contains('Produto não encontrado')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto já foi removido ou não existe.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir produto: $e')),
          );
        }
      }
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
    });
    try {
      final dados = await api.fetchDados('categorias');
      final novasCategorias = dados.map<Categoria>((json) => Categoria.fromJson(json)).toList();
      print('Categorias carregadas: \n' + novasCategorias.map((c) => 'id: ${c.id}, nome: ${c.nome}').join(', '));
      setState(() {
        _categorias = novasCategorias;
        // Corrige o valor do filtro se a categoria selecionada não existir mais
        if (_categorias.isEmpty) {
          _categoriaFiltroSelecionada = null;
        } else if (_categoriaFiltroSelecionada != null && !_categorias.any((c) => c.id == _categoriaFiltroSelecionada)) {
          _categoriaFiltroSelecionada = null;
        }
      });
      // Atualiza o Provider global
      _appState.setCategorias(novasCategorias);
    } catch (e) {
      setState(() {
        _categorias = [];
        _categoriaFiltroSelecionada = null;
      });
      _appState.setCategorias([]);
    } finally {
      setState(() {
        _carregandoCategorias = false;
      });
    }
  }

  Future<void> _criarCategoria() async {
    final nomeController = TextEditingController();
    final authModel = Provider.of<AuthModel>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Categoria'),
          content: TextField(
            controller: nomeController,
            decoration: const InputDecoration(labelText: 'Nome da Categoria'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome da categoria não pode ser vazio.')),
                  );
                  return;
                }
                try {
                  final dynamic ok = await api.createItem('categorias', {'nome': nome});
                  if (ok == true || (ok is Map && ok['id'] != null)) {
                    Navigator.pop(context);
                    await _carregarCategorias();
                    setState(() {}); // Força rebuild dos Dropdowns
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoria criada com sucesso!')),
                    );
                  } else if (ok is Map) {
                    final Map<String, dynamic> okMap = ok as Map<String, dynamic>;
                    String? errorMessage;
                    if (okMap.containsKey('message') && okMap['message'] != null) {
                      errorMessage = okMap['message'].toString();
                    } else if (okMap.containsKey('error') && okMap['error'] != null) {
                      errorMessage = okMap['error'].toString();
                    }
                    if (errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao criar categoria: Resposta inesperada da API.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao criar categoria. Verifique se o nome já existe ou tente novamente.')),
                    );
                  }
                } catch (e, stack) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar categoria: $e')),
                  );
                  print('Erro ao criar categoria:');
                  print(e);
                  print(stack);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Função para filtrar produtos por nome e categoria
  List<Produto> _filtrarProdutos(List<Produto> produtos) {
    final busca = _textController.text.trim().toLowerCase();
    final categoriaSelecionada = _categoriaFiltroSelecionada;
    return produtos.where((p) {
      final nomeOk = busca.isEmpty || p.nome.toLowerCase().contains(busca);
      final categoriaOk = categoriaSelecionada == null || p.categoriaId == categoriaSelecionada;
      return nomeOk && categoriaOk;
    }).toList();
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
    final appState = Provider.of<AppState>(context);
    final emailUsuario = authModel.usuario?.email ?? 'email@exemplo.com';
    final nomeUsuario = authModel.usuario?.nome ?? 'Usuário';

    // Calcula o total de produtos, estoque baixo e categorias únicas usando AppState
    final produtos = appState.produtos;
    int totalProdutos = produtos.length;
    int estoqueBaixo = produtos.where((p) => p.quantidade <= 10).length;
    Set<String> categoriasUnicas = produtos.map((p) => p.categoriaId ?? '').where((id) => id.isNotEmpty).toSet();
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
    final appState = Provider.of<AppState>(context);
    final produtos = appState.produtos;
    int totalEmEstoque = produtos.fold(0, (sum, p) => sum + p.quantidade);
    int estoqueBaixo = produtos.where((p) => p.quantidade <= 10).length;

    return FutureBuilder<int>(
      future: api.fetchMovimentacoesHoje(),
      builder: (context, movSnapshot) {
        int movimentacoes = 0;
        if (movSnapshot.hasData) {
          movimentacoes = movSnapshot.data!;
        }
        return GridView.count(
          crossAxisCount: 3,
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
              trend: 'INSERIR OBSERVAÇÃO DEPOIS',
              iconBgColor: Colors.orange,
            ),
            _buildSummaryCard(
              context,
              title: 'Estoque Baixo',
              value: estoqueBaixo.toString(),
              icon: Icons.warning_amber,
              trend: 'INSERIR OBSERVAÇÃO DEPOIS',
              iconBgColor: Colors.red,
            ),
            _buildSummaryCard(
              context,
              title: 'Movimentações',
              value: movimentacoes.toString(),
              icon: Icons.swap_vert,
              trend: 'INSERIR OBSERVAÇÃO DEPOIS',
              iconBgColor: Colors.green,
            ),
          ],
        );
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
            onChanged: _onSearchChanged,
          ),
        ),
        IconButton(
          tooltip: 'Atualizar lista de produtos',
          icon: const Icon(Icons.refresh, color: Colors.orange, size: 28),
          onPressed: () async {
            await _appState.carregarProdutosDaApi();
            await _carregarCategorias();
            setState(() {}); // Força rebuild dos Dropdowns
          },
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
            value: _categoriaFiltroSelecionada,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Sem filtro'),
              ),
              ..._categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
            ],
            onChanged: (value) {
              setState(() {
                _categoriaFiltroSelecionada = value;
              });
            },
            isExpanded: true,
            disabledHint: const Text('Cadastre uma categoria primeiro'),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _criarCategoria,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.category),
          label: const Text('Nova Categoria'),
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
    final appState = Provider.of<AppState>(context);
    final produtos = appState.produtos;
    // Usar a nova função de filtro combinada
    final filteredProdutos = _filtrarProdutos(produtos);

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
            child: appState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProdutos.isEmpty
                    ? const Center(child: Text('Nenhum produto encontrado.'))
                    : SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columns: [
                            const DataColumn(label: Text('PRODUTO', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('CATEGORIA', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('QUANTIDADE', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('AÇÕES', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredProdutos.map((produto) {
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
                              DataCell(
                                Builder(
                                  builder: (context) {
                                    final catId = produto.categoriaId;
                                    if (catId == null || catId.isEmpty) {
                                      return const Text('Sem categoria', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
                                    }
                                    // Use a lista do provider, não a lista local _categorias
                                    final cat = appState.categorias.firstWhere(
                                      (c) => c.id == catId,
                                      orElse: () => Categoria(id: '', nome: 'Carregando...'), // Fallback
                                    );
                                    if (cat.id.isEmpty) {
                                      return Text('ID Inválido: [33m${catId.substring(0, 5)}...\u001b[0m', style: const TextStyle(color: Colors.orange));
                                    }
                                    return Text(cat.nome);
                                  },
                                ),
                              ),
                              DataCell(Text(produto.quantidade.toString())),
                              DataCell(_buildStatusChip(produto.quantidade)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'Ver Detalhes',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProdutoDetalhesPage(
                                            produto: produto,
                                            onProdutoEditado: (produtoEditado) async {
                                              await _appState.carregarProdutosDaApi();
                                              await _carregarCategorias();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
                          }).toList(),
                          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                          dataRowColor: MaterialStateProperty.all(Colors.white),
                          border: TableBorder.all(color: Colors.grey[200]!),
                          columnSpacing: 30,
                          horizontalMargin: 10,
                          headingRowHeight: 50,
                          dataRowHeight: 70,
                          showCheckboxColumn: false,
                        ),
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