import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_model.dart';

class AuthPage extends StatelessWidget {
  final Function(BuildContext, AuthModel) onLogin;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Widget? extraWidget;

  const AuthPage({
    super.key,
    required this.onLogin,
    required this.usernameController,
    required this.passwordController,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo ajustada para cobrir toda a tela
          Image.asset(
            'lib/images/fundo.jpg', // Imagem local de fundo
            fit: BoxFit.cover,
          ),
          
          Positioned(
            top: MediaQuery.of(context).size.height * 0.16, // Centraliza melhor
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/images/Marca_Bright_Bee_(Gradiente_Horizontal_Positivo).png',
                height: 150,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<AuthModel>(
                builder: (context, authModel, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      _buildTextInput(
                        controller: usernameController,
                        label: 'Nome de Usuário',
                        obscureText: false,
                      ),
                      const SizedBox(height: 15.0),
                      _buildTextInput(
                        controller: passwordController,
                        label: 'Senha',
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      _buildLoginButton(
                        context: context,
                        authModel: authModel,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
  }) {
    return Container(
      height: 55.0, // Ajustado altura do campo
      width: 300.0, // Ajustado largura do campo para ser mais responsivo, ou pode ser um valor fixo
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Levemente transparente
        borderRadius: BorderRadius.circular(30.0), // Borda mais arredondada
        border: Border.all(color: const Color(0xFFF9DC5C), width: 2.0), // Cor da borda amarela do site
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // Sombra suave
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none, // Remove a borda interna do TextField
          labelStyle: const TextStyle(color: Color(0xFF5D5D5D)), // Cor do texto do label
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0), // Ajuste do padding
        ),
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required AuthModel authModel,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await onLogin(context, authModel);

            if (authModel.isAuthenticated) {
              // Usuário autenticado com sucesso, sem mensagens adicionais
            } else {
              // Exibe mensagem de erro se o login falhar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuário ou senha inválidos!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF9DC5C), // Cor amarela do site
            foregroundColor: const Color(0xFF5D5D5D), // Cor do texto do botão
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), // Ajuste do padding do botão
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0), // Borda mais arredondada
            ),
            elevation: 5, // Sombra para o botão
          ),
          child: const Text(
            'ENTRAR', // Texto em maiúsculas
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (extraWidget != null) ...[
          const SizedBox(height: 16),
          extraWidget!,
        ],
      ],
    );
  }
}