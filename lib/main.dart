import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_model.dart' as auth_model;
import 'pages/auth_page.dart';
import 'pages/my_home_page.dart';
import 'providers/app_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  Provider.debugCheckInvalidValueType = null;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => auth_model.AuthModel(navigatorKey)),
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicação do estoque',
      theme: ThemeData(
        primaryColor: const Color(0xFF007BFF), // Cor azul vibrante como primaryColor
        hintColor: const Color(0xFFF9DC5C), // Cor amarela para realces
        // Outras configurações de tema podem ser adicionadas aqui
      ),
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': _rootRoute,
        '/home': (context) => const MyHomePage(),
        '/login': _loginRoute,
      },
    );
  }

  Widget _rootRoute(BuildContext context) {
    return Consumer<auth_model.AuthModel>(
      builder: (context, authModel, child) {
        if (authModel.isAuthenticated) {
          return const MyHomePage();
        } else {
          return AuthPage(
            onLogin: (context, authModel) async {
              await authModel.login(
                authModel.usernameController.text,
                authModel.passwordController.text,
              );
            },
            usernameController: authModel.usernameController,
            passwordController: authModel.passwordController,
            // Adiciona um botão de teste de conexão na tela de login
            extraWidget: ConnectionTestButton(),
          );
        }
      },
    );
  }

  Widget _loginRoute(BuildContext context) {
    return Consumer<auth_model.AuthModel>(
      builder: (context, authModel, child) {
        return AuthPage(
          onLogin: (context, authModel) async {
            await authModel.login(
              authModel.usernameController.text,
              authModel.passwordController.text,
            );
          },
          usernameController: authModel.usernameController,
          passwordController: authModel.passwordController,
        );
      },
    );
  }
}

// Widget para testar conexão com a API e mostrar resultado
class ConnectionTestButton extends StatefulWidget {
  @override
  State<ConnectionTestButton> createState() => _ConnectionTestButtonState();
}

class _ConnectionTestButtonState extends State<ConnectionTestButton> {
  String? _result;
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() { _loading = true; _result = null; });
    try {
      final response = await Uri.parse('http://192.168.2.115:3000/usuarios');
      final res = await http.get(response);
      if (res.statusCode == 200) {
        final users = jsonDecode(res.body);
        setState(() {
          _result = 'Conexão OK! Usuários cadastrados: \\${users.length}';
        });
      } else {
        setState(() {
          _result = 'Erro: status \\${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro: \\${e.toString()}';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _testConnection,
          icon: const Icon(Icons.wifi),
          label: Text(_loading ? 'Testando...' : 'Testar conexão'),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_result!, style: TextStyle(color: _result!.contains('OK') ? Colors.green : Colors.red)),
          ),
      ],
    );
  }
}