import 'package:flutter/material.dart';
import '../consumer_api.dart';

class UsuariosPage extends StatefulWidget {
  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<Map<String, dynamic>> _usuarios = [];
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    try {
      final usuarios = await fetchUsuarios();
      setState(() {
        _usuarios = usuarios;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuários: $e')),
      );
    }
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        await createUsuario({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'login': _loginController.text,
          'senha': _senhaController.text,
        });
        _carregarUsuarios();
        _nomeController.clear();
        _emailController.clear();
        _loginController.clear();
        _senhaController.clear();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar usuário: $e')),
        );
      }
    }
  }

  Future<void> _excluirUsuario(String id) async {
    try {
      await deleteUsuario(id);
      _carregarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007BFF), // Cor azul vibrante
        iconTheme: const IconThemeData(color: Colors.white), // Ícones brancos
      ),
      body: _usuarios.isEmpty
          ? const Center(child: Text('Nenhum usuário encontrado.'))
          : ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0),
              title: Text(usuario['nomeUsuario'] ?? 'Nome não disponível', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
              subtitle: Text(usuario['emailUsuario'] ?? 'Email não disponível', style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFDC3545)), // Cor do ícone de exclusão
                onPressed: () => _excluirUsuario(usuario['idUsuario']?.toString() ?? ''),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Adicionar Usuário', style: TextStyle(color: Color(0xFF333333))),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(labelText: 'Login'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _senhaController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF555555))),
                ),
                ElevatedButton(
                  onPressed: _adicionarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF), // Cor azul vibrante
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFF007BFF), // Cor azul vibrante
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}