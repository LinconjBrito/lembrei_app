import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/atividade.dart';

class AtividadeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Atividade>> getByUser(int userId) async {
    final results = await _client
        .from('atividades')
        .select()
        .eq('id_usuario', userId)
        .order('created_at', ascending: false);

    return results
        .whereType<Map<String, dynamic>>()
        .map(Atividade.fromMap)
        .toList();
  }

  Future<Atividade?> insert(Map<String, dynamic> data) async {
    final inserted = await _client.from('atividades').insert(data).select();
    if (inserted.isEmpty) return null;
    return Atividade.fromMap(inserted.first);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _client.from('atividades').update(data).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _client.from('atividades').delete().eq('id', id);
  }
}
