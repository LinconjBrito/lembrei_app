import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/usuario.dart';
import 'current_user.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final nome = _nomeController.text.trim();
    final senha = _senhaController.text;
    if (nome.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e senha')),
      );
      return;
    }

    final client = Supabase.instance.client;
    try {
      final results = await client
          .from('usuario')
          .select()
          .eq('nome', nome)
          .eq('senha', senha)
          .limit(1);

      if (results.isNotEmpty) {
        final userMap = results.first as Map<String, dynamic>?;
        final ativo = userMap?['ativo'] as bool?;
        if (ativo == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta desativada. Contate o administrador.')),
          );
          return;
        }

        if (userMap != null) {
          final usuario = Usuario.fromDocument(userMap);
          currentUser.value = usuario;
        }

        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário ou senha inválidos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao autenticar: $e')),
      );
    }
  }

  Future<void> _createAccount() async {
    final nome = _nomeController.text.trim();
    final senha = _senhaController.text;
    if (nome.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e senha')),
      );
      return;
    }

    final client = Supabase.instance.client;
    try {
      final inserted = await client.from('usuario').insert({
        'nome': nome,
        'senha': senha,
        'ativo': true,
      }).select();

      if (inserted.isNotEmpty) {
        final insertedUser = inserted.first as Map<String, dynamic>?;
        if (insertedUser != null) {
          final usuario = Usuario.fromDocument(insertedUser);
          currentUser.value = usuario;
        }
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar a conta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 100, title: Padding(
        padding: const EdgeInsets.only(top: 50.0),
      child: Center(child: const Text('Lembrei :)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),)),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('Entrar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _createAccount,
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
