import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

/// Página de debug para testar conexão Supabase e diagnóstico
class DebugSupabasePage extends StatefulWidget {
  const DebugSupabasePage({super.key});

  @override
  State<DebugSupabasePage> createState() => _DebugSupabasePageState();
}

class _DebugSupabasePageState extends State<DebugSupabasePage> {
  String _output = '';

  void _addLog(String msg) {
    debugPrint('[DEBUG] $msg');
    setState(() {
      _output += '$msg\n';
    });
  }

  Future<void> _testConnection() async {
    _output = '';
    _addLog('=== Iniciando teste de conexão ===');

    try {
      final client = Supabase.instance.client;
      _addLog('✓ Cliente Supabase obtido');

      // Teste 1: SELECT simples
      _addLog('\n--- Teste 1: SELECT sem filtros ---');
      final results = await client.from('atividades').select();
      _addLog('Tipo da resposta: ${results.runtimeType}');
      _addLog('Comprimento: ${results.length}');
      _addLog('Conteúdo: ${results.toString()}');

      if (results.isEmpty) {
        _addLog('⚠️ Array vazio retornado');
        
        // Teste 2: Verificar se a tabela existe
        _addLog('\n--- Teste 2: Tentar SELECT com limit 1 ---');
        final limited = await client.from('atividades').select().limit(1);
        _addLog('Resultado com limit: $limited');

        // Teste 3: SELECT com colunas específicas
        _addLog('\n--- Teste 3: SELECT de colunas específicas ---');
        final specific = await client
          .from('atividades')
          .select('id, nome, horario');
        _addLog('Resultado específico: $specific');

        // Teste 4: Contar registros
        _addLog('\n--- Teste 4: COUNT ---');
        try {
          final count = await client.from('atividades').select('count()');
          _addLog('Count result: $count');
        } catch (e) {
          _addLog('Count erro: $e');
        }
      } else {
        _addLog('✓ Dados encontrados: ${results.length} registros');
        _addLog('Primeiro registro: ${results.first}');
      }

      // Teste 5: Verificar usuários (se tabela existir)
      _addLog('\n--- Teste 5: SELECT usuarios ---');
      try {
          final usuarios = await client.from('usuario').select();
        _addLog('✓ Usuários: ${usuarios.length} encontrados');
        if (usuarios.isNotEmpty) {
          _addLog('Primeiro usuário: ${usuarios.first}');
        }
      } catch (e) {
          _addLog('❌ Erro ao consultar usuario: $e');
      }

      _addLog('\n=== Teste concluído ===');
    } catch (e, st) {
      _addLog('❌ Erro: $e');
      _addLog('Stack: $st');
    }
  }

  Future<void> _insertTestData() async {
    _output = '';
    _addLog('=== Inserindo dados de teste ===');

    try {
      final client = Supabase.instance.client;

      // Primeiro, tenta inserir um usuário
      _addLog('Tentando inserir usuário de teste...');
        final userResult = await client
            .from('usuario')
          .insert({
            'nome': 'Usuário Teste',
            'senha': 'senha123', // NUNCA faça isso em produção
          })
          .select();
      
      _addLog('✓ Usuário inserido: $userResult');
      
      if (userResult.isNotEmpty) {
        final userId = userResult.first['id'] as int;
        _addLog('User ID: $userId');

        // Agora insere uma atividade
        _addLog('Inserindo atividade de teste...');
        final actResult = await client
            .from('atividades')
              .insert({
                'nome': 'Atividade Teste',
              'horario': '10:30:00',
              'id_usuario': userId,
            })
            .select();

        _addLog('✓ Atividade inserida: $actResult');
      }

      _addLog('\n=== Dados inseridos com sucesso ===');
    } catch (e, st) {
      _addLog('❌ Erro ao inserir: $e');
      _addLog('Stack: $st');
    }
  }

  Future<void> _clearTestData() async {
    _output = '';
    _addLog('=== Limpando dados de teste ===');

    try {
      final client = Supabase.instance.client;

      // Deletar atividades
      _addLog('Deletando atividades...');
      await client.from('atividades').delete().gt('id', 0);
      _addLog('✓ Atividades deletadas');

      // Deletar usuários
      _addLog('Deletando usuários...');
        await client.from('usuario').delete().gt('id', 0);
      _addLog('✓ Usuários deletados');

      _addLog('\n=== Limpeza concluída ===');
    } catch (e, st) {
      _addLog('❌ Erro ao limpar: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Supabase')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testConnection,
                  child: const Text('Testar Conexão'),
                ),
                ElevatedButton(
                  onPressed: _insertTestData,
                  child: const Text('Inserir Dados'),
                ),
                ElevatedButton(
                  onPressed: _clearTestData,
                  child: const Text('Limpar Dados'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _output = ''),
                  child: const Text('Limpar Log'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _output.isEmpty ? 'Clique em um botão para iniciar testes' : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
