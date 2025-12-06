import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/usuario.dart';
import 'current_user.dart';
import 'providers/current_user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  Future<void> _signInWithCredentials(String nome, String senha) async {
    if (nome.trim().isEmpty || senha.isEmpty) {
      if (!mounted) return;
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
          .eq('nome', nome.trim())
          .eq('senha', senha)
          .limit(1);

      if (results.isNotEmpty) {
        final userMap = results.first as Map<String, dynamic>?;
        final ativo = userMap?['ativo'] as bool?;
        if (ativo == false) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta desativada. Contate o administrador.')),
          );
          return;
        }

        if (userMap != null) {
          final usuario = Usuario.fromDocument(userMap);
          currentUser.value = usuario;
          ref.read(currentUserIdProvider.notifier).state = usuario.id;
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário ou senha inválidos')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao autenticar: $e')));
    }
  }

  Future<void> _createAccountWithCredentials(String nome, String senha) async {
    if (nome.trim().isEmpty || senha.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e senha')),
      );
      return;
    }

    final client = Supabase.instance.client;
    try {
      final inserted = await client.from('usuario').insert({
        'nome': nome.trim(),
        'senha': senha,
        'ativo': true,
      }).select();

      if (inserted.isNotEmpty) {
        final insertedUser = inserted.first as Map<String, dynamic>?;
        if (insertedUser != null) {
          final usuario = Usuario.fromDocument(insertedUser);
          currentUser.value = usuario;
          ref.read(currentUserIdProvider.notifier).state = usuario.id;
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível criar a conta')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar conta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.event_note, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Lembrei App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Acesse sua conta para ver e receber lembretes', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Entrar', style: TextStyle(fontSize: 16)),
                      ),
                      onPressed: () => _showSignInDialog(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Criar conta', style: TextStyle(fontSize: 16)),
                      ),
                      onPressed: () => _showCreateAccountDialog(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Feito com ♥ para estudos', style: TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSignInDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final senhaController = TextEditingController();
    bool obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Entrar'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person)),
                  autofocus: true,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Preencha o nome' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senhaController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  obscureText: obscure,
                  validator: (v) => (v == null || v.isEmpty) ? 'Preencha a senha' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      }),
    );

    if (result == true) {
      await _signInWithCredentials(nomeController.text, senhaController.text);
    }
  }

  void _showCreateAccountDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final senhaController = TextEditingController();
    bool obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Criar conta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person)),
                  autofocus: true,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Preencha o nome' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senhaController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  obscureText: obscure,
                  validator: (v) => (v == null || v.length < 4) ? 'Senha muito curta' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      }),
    );

    if (result == true) {
      await _createAccountWithCredentials(nomeController.text, senhaController.text);
    }
  }
}
