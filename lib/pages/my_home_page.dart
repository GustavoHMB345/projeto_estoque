// Importações necessárias para o funcionamento da página
import 'package:flutter/material.dart';
import 'package:projeto_estoque/pages/produto_detalhes_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import '../consumer_api.dart';
import '../models/categoria.dart';
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
    final predioController = TextEditingController();
    final quantidadeController = TextEditingController();
    final condicaoController = TextEditingController(text: 'novo');
    String? categoriaSelecionada;

    // Buscar categorias existentes
    final categorias = await fetchCategorias();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                items: categorias.map((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria['nome_categoria'] as String, // Use nome_categoria directly
                    child: Text(categoria['nome_categoria'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  categoriaSelecionada = value;
                },
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
              ),
              TextField(
                controller: predioController,
                decoration: const InputDecoration(labelText: 'Predio'),
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
                onChanged: (value) {
                  condicaoController.text = value ?? 'novo';
                },
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
                if (categoriaSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione uma categoria.')),
                  );
                  return;
                }

                final produto = Produto(
                  nome: nomeController.text.trim(),
                  condicao: condicaoController.text,
                  predio: predioController.text.trim(),
                  quantidade: int.tryParse(quantidadeController.text.trim()) ?? 0,
                  criadoEm: DateTime.now(),
                  categoriaId: categoriaSelecionada ?? '',
                  nomeCategoria: categorias.firstWhere((cat) => cat['id'] == categoriaSelecionada)['nome_categoria'] ?? '',
                );

                final response = await createProduto(produto);
                if (!mounted) return;
                if (response) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Produto criado com sucesso!')),
                    );
                  }
                  if (mounted) Navigator.pop(context);
                } else {
                  _logger.severe('Erro ao salvar o produto. Verifique os dados enviados e a conexão com a API.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar produto: Verifique os dados e tente novamente.')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarCategoria() async {
    final categoriaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Criar Categoria'),
          content: TextField(
            controller: categoriaController,
            decoration: const InputDecoration(labelText: 'Nome da Categoria'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final categoria = categoriaController.text.trim();
                if (categoria.isNotEmpty) {
                  final response = await createCategoria(categoria);
                  if (!mounted) return;
                  if (response) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoria criada com sucesso!')),
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao criar categoria.')),
                      );
                    }
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Updated to fetch data directly from the produtos table
  Future<List<Map<String, dynamic>>> fetchProdutos() async {
    return await fetchDados('produtos');
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
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _adicionarCategoria,
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
                future: fetchProdutos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar produtos: ${snapshot.error}',
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
                                      Text('Categoria: ${produto.nomeCategoria}'),
                                      Text('Condição: ${produto.condicao}'),
                                      Text('Predio: ${produto.predio}'),
                                      Text('Quantidade: ${produto.quantidade}'),
                                      Text('Criado em: '
                                          '${produto.criadoEm.toLocal().day.toString().padLeft(2, '0')}-'
                                          '${produto.criadoEm.toLocal().month.toString().padLeft(2, '0')}-'
                                          '${produto.criadoEm.toLocal().year.toString().substring(2)}'),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProdutoDetalhesPage(produto: produto),
                                      ),
                                    );
                                  },
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
              _buildSectionTitle('Categorias'),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDados('categorias'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar categorias'));
                  } else if (snapshot.hasData) {
                    final categorias = snapshot.data?.map((json) => Categoria.fromJson(json)).toList() ?? [];
                    return categorias.isEmpty
                        ? const Center(child: Text('Nenhuma categoria encontrada'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categorias.length,
                            itemBuilder: (context, index) {
                              final categoria = categorias[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(categoria.nome),
                                  subtitle: Text('Descrição: ${categoria.descricao}'),
                                ),
                              );
                            },
                          );
                  } else {
                    return const Center(child: Text('Nenhum dado encontrado'));
                  }
                },
              ),
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


