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
        title: Text('Gerenciar Usuários'),
      ),
      body: ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          return ListTile(
            title: Text(usuario['nomeUsuario'] ?? 'Nome não disponível'),
            subtitle: Text(usuario['emailUsuario'] ?? 'Email não disponível'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _excluirUsuario(usuario['idUsuario']?.toString() ?? ''),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Adicionar Usuário'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(labelText: 'Nome'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _loginController,
                      decoration: InputDecoration(labelText: 'Login'),
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _senhaController,
                      decoration: InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _adicionarUsuario,
                  child: Text('Adicionar'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
