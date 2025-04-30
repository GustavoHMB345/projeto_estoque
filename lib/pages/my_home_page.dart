// Importações necessárias para o funcionamento da página
import 'package:flutter/material.dart';
import 'package:projeto_estoque/pages/produto_detalhes_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import '../consumer_api.dart';
import '../models/categoria.dart';
import '../models/produto.dart';
import '../models/movimentacao_estoque.dart';

// Definição do widget principal da página inicial
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

// Estado associado ao widget MyHomePage
class MyHomePageState extends State<MyHomePage> {
  // Controladores de texto e chaves para gerenciar estado e entradas
  final _textController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AppState _appState;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        centerTitle: true,
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
                    return const Center(child: Text('Erro ao carregar produtos'));
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
                                      Text('Categoria: ${produto.categoriaId}'),
                                      Text('Condição: ${produto.condicao}'),
                                      Text('Unidade: ${produto.unidade}'),
                                      Text('Quantidade: ${produto.quantidade}'),
                                      Text('Preço Unitário: R\$ ${produto.precoUnitario.toStringAsFixed(2)}'),
                                      Text('Criado em: ${produto.criadoEm.toLocal()}'),
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
              const SizedBox(height: 16),
              _buildSectionTitle('Movimentações de Estoque'),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDados('movimentacoes_estoque'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar movimentações'));
                  } else if (snapshot.hasData) {
                    final movimentacoes = snapshot.data?.map((json) => MovimentacaoEstoque.fromJson(json)).toList() ?? [];
                    return movimentacoes.isEmpty
                        ? const Center(child: Text('Nenhuma movimentação encontrada'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: movimentacoes.length,
                            itemBuilder: (context, index) {
                              final movimentacao = movimentacoes[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text('Produto ID: ${movimentacao.produtoId}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tipo: ${movimentacao.tipo}'),
                                      Text('Quantidade: ${movimentacao.quantidade}'),
                                      Text('Data: ${movimentacao.dataMovimentacao.toLocal()}'),
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

  // Função de callback para login
  void onLogin(BuildContext context, AuthModel authModel) {
    final username = _usernameController.text;
    final password = _passwordController.text;
    authModel.login(username, password);

    if (authModel.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home'); // Navega para a página inicial
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login falhou'), // Mensagem de falha no login
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


