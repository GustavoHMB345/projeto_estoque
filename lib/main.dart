import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_model.dart' as auth_model;
import 'pages/auth_page.dart';
import 'pages/my_home_page.dart';
import 'providers/app_state.dart';


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
            onLogin: (context, authModel) {
              authModel.login(
                authModel.usernameController.text,
                authModel.passwordController.text,
              );
            },
            usernameController: authModel.usernameController,
            passwordController: authModel.passwordController,
          );
        }
      },
    );
  }

  Widget _loginRoute(BuildContext context) {
    return Consumer<auth_model.AuthModel>(
      builder: (context, authModel, child) {
        return AuthPage(
          onLogin: (context, authModel) {
            authModel.login(
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