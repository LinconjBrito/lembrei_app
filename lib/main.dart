import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/auth_provider.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/current_user.dart';
import 'package:myapp/models/usuario.dart';



const authenticationEnabled = true;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Function.apply(Supabase.initialize, [], supabaseOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        home: authenticationEnabled ? AuthenticationWrapper() : const MainPage(),
        routes: {
          '/home': (context) => const MainPage(),
        },
      ),
    );
  }
}

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
        actions: [
          ValueListenableBuilder<Usuario?>(
            valueListenable: currentUser,
            builder: (context, usuario, _) {
              if (usuario == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const CircleAvatar(child: Icon(Icons.person)),
                onSelected: (value) async {
                  final client = Supabase.instance.client;
                  if (value == 'alterar_senha') {
                    final controller = TextEditingController();
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Alterar senha'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(labelText: 'Nova senha'),
                          obscureText: true,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Salvar')),
                        ],
                      ),
                    );

                    if (result != null && result.isNotEmpty) {
                      try {
                        await client.from('usuario').update({'senha': result}).eq('id', usuario.id!).select();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha atualizada')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar senha: $e')));
                      }
                    }
                  } else if (value == 'deletar_usuario') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Deletar usuário'),
                        content: const Text('Tem certeza que deseja desativar sua conta?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await client.from('usuario').update({'ativo': false}).eq('id', usuario.id!).select();
                        currentUser.value = null;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta desativada')));
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao desativar conta: $e')));
                      }
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'alterar_senha', child: Text('Alterar senha')),
                  PopupMenuItem(value: 'deletar_usuario', child: Text('Deletar usuário')),
                ],
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bem-vindo — sistema de atividades removido temporariamente'),
      ),
    );
  }
}

class AuthenticationWrapper extends ConsumerWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (AuthState state) {
        return state.session == null ? const LoginPage() : const MainPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) {
        return Scaffold(body: Center(child: Text('Error: $error')));
      },
    );
  }
}

