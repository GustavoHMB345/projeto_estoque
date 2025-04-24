import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';
import '../providers/app_state.dart';
import 'login_page.dart';
import 'package:projeto_estoque/consumer_api.dart';
import 'aparato_detalhes_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _textController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _futureItens;

  @override
  void initState() {
    super.initState();
    _futureItens = fetchDados('');
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppState>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(appStateManager),
      body: _buildBody(),
    );
  }

 

  Drawer _buildDrawer(AppState appStateManager) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(appStateManager),
          _buildDrawerList(),
        ],
      ),
    );
  }

  DrawerHeader _buildDrawerHeader(AppState appStateManager) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.brown, 
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.yellow, 
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              appStateManager.headerText,
              style: const TextStyle(
                color: Colors.yellow, 
                fontSize: 24, 
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerList() {
    return Consumer<AppState>(
      builder: (context, appStateManager, child) {
        return Column(
          mainAxisAlignment: appStateManager.mainAxisAlignment,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Voltar'),
              onTap: () {
                Navigator.pop(context);
                appStateManager.updateHeaderText('Voltou para a tela anterior');
                appStateManager.updateMainAxisAlignment(MainAxisAlignment.spaceAround);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Provider.of<AuthModel>(context, listen: false).logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(
                      onLogin: onLogin,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                    ),
                  ),
                );
                appStateManager.updateHeaderText('Você saiu');
                appStateManager.updateMainAxisAlignment(MainAxisAlignment.spaceEvenly);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 400, 
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar categoria',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 19), 
          ElevatedButton(
            onPressed: () async {
              final categoriaEquipamento = _textController.text.trim();
              if (categoriaEquipamento.isNotEmpty) {
                setState(() {
                  _futureItens = fetchDados(categoriaEquipamento);
                });
              }
            },
            style: ButtonStyle(
             backgroundColor: WidgetStateProperty.all<Color>(Color.fromARGB(170, 46, 35, 14)),
            foregroundColor: WidgetStateProperty.all<Color>(Colors.yellow), 
            ),
            child: const Text('Buscar'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureItens,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar dados'),
                  );
                } else if (snapshot.hasData) {
                  final itens = snapshot.data ?? [];
                  return itens.isEmpty
                      ? const Center(child: Text('Nenhuma categoria encontrada'))
                      : ListView.builder(
                          itemCount: itens.length,
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  item['equipamento'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Text('Quantidade: ${item['quantidade'] ?? 0}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AparatoDetalhesPage(aparato: item),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                } else {
                  return const Center(
                    child: Text('Nenhum dado encontrado'),
                  );
                }
              },
            ),
          ),
        ],
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
}
