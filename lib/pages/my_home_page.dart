// Importações necessárias para o funcionamento da página
import 'package:flutter/material.dart';
import 'package:projeto_estoque/pages/produto_detalhes_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import '../consumer_api.dart';
import '../models/produto.dart';
import 'package:logging/logging.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _textController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AppState _appState;
  final _logger = Logger('MyHomePage');

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = Provider.of<AppState>(context, listen: false);
    _appState.addListener(_updateDataFromApi);
  }

  @override
  void dispose() {
    _appState.removeListener(_updateDataFromApi);
    _textController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateDataFromApi() {
    setState(() {});
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
                  setState(() {});
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
                final atualizado = Produto(
                  id: produto.id,
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                  criadoEm: produto.criadoEm,
                );
                final response = await updateItem('produtos', produto.id, atualizado.toJson(includeDataCriacao: false));
                if (!mounted) return;
                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto atualizado com sucesso!')),
                  );
                  Navigator.pop(context);
                  setState(() {});
                } else {
                  _logger.severe('Erro ao atualizar o produto. Verifique os dados enviados e a conexão com a API.');
                  // Log no terminal do VS Code
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _adicionarProduto,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Produtos'),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDados('produtos'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar produtos: \\${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final produtos = snapshot.data?.map((json) => Produto.fromJson(json)).toList() ?? [];
                    return produtos.isEmpty
                        ? const Center(child: Text('Nenhum produto encontrado'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: produtos.length,
                            itemBuilder: (context, index) {
                              final produto = produtos[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(produto.nome),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Condição: \\${produto.condicao}'),
                                      Text('Quantidade: \\${produto.quantidade}'),
                                      Text('Criado em: '
                                          '\\${produto.criadoEm.toLocal().day.toString().padLeft(2, '0')}-'
                                          '\\${produto.criadoEm.toLocal().month.toString().padLeft(2, '0')}-'
                                          '\\${produto.criadoEm.toLocal().year.toString().substring(2)}'),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProdutoDetalhesPage(
                                          produto: produto,
                                          onProdutoEditado: (Produto atualizado) async {
                                            final response = await updateItem('produtos', atualizado.id, atualizado.toJson(includeDataCriacao: false));
                                            if (response) {
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Produto atualizado com sucesso!')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Erro ao atualizar produto.')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Editar',
                                        onPressed: () => _editarProduto(produto),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Excluir',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Excluir Produto'),
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
                                            final ok = await deleteItem('produtos', produto.id);
                                            if (ok) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Produto excluído com sucesso!')),
                                              );
                                              setState(() {});
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Erro ao excluir produto.')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                  } else {
                    return const Center(child: Text('Nenhum dado encontrado'));
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void onLogin(BuildContext context, AuthModel authModel) {
    final username = _usernameController.text;
    final password = _passwordController.text;
    authModel.login(username, password);

    if (authModel.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login falhou'),
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu Principal', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorias'),
            onTap: () {
              // Implementar navegação para a página de categorias
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produtos'),
            onTap: () {
              // Implementar navegação para a página de produtos
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Implementar lógica de logout
            },
          ),
        ],
      ),
    );
  }
}


