import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/atividade.dart';
import 'providers/current_user_provider.dart';
import 'notification_service.dart';

class ActivitiesList extends ConsumerStatefulWidget {
  const ActivitiesList({super.key});

  @override
  ConsumerState<ActivitiesList> createState() => _ActivitiesListState();
}

class _ActivitiesListState extends ConsumerState<ActivitiesList> {
  List<Atividade> _items = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final results = await client
          .from('atividades')
          .select()
          .eq('id_usuario', userId)
          .order('created_at', ascending: false);

      final list = <Atividade>[];
      for (final r in results) {
        if (r is Map<String, dynamic>) {
          list.add(Atividade.fromMap(r));
        }
      }
      setState(() => _items = list);
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addActivity() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final nomeController = TextEditingController();
    TimeOfDay? chosenTime;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Adicionar atividade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text(chosenTime != null ? 'Horário: ${chosenTime!.format(context)}' : 'Sem horário'),
                ),
                TextButton(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setState(() => chosenTime = t);
                  },
                  child: const Text('Escolher horário'),
                )
              ])
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Adicionar')),
          ],
        );
      }),
    );

    if (ok != true) return;

    final nome = nomeController.text.trim();
    if (nome.isEmpty) return;

    String? horarioString;
    if (chosenTime != null) {
      final hh = chosenTime!.hour.toString().padLeft(2, '0');
      final mm = chosenTime!.minute.toString().padLeft(2, '0');
      horarioString = '$hh:$mm:00';
    }

    try {
      final client = Supabase.instance.client;
      final inserted = await client.from('atividades').insert({
        'nome': nome,
        'horario': horarioString,
        'id_usuario': userId,
      }).select();

      if (inserted.isNotEmpty) {
        final created = inserted.first as Map<String, dynamic>?;
        if (created != null) {
          final atividade = Atividade.fromMap(created);
          if (atividade.horario != null && atividade.id != null) {
            await NotificationService().scheduleActivityNotification(atividade);
          }
        }
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Faça login para ver suas atividades.'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Suas atividades', style: TextStyle(fontWeight: FontWeight.w600))),
                TextButton.icon(onPressed: _addActivity, icon: const Icon(Icons.add), label: const Text('Adicionar')),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Nenhuma atividade encontrada', textAlign: TextAlign.center),
              ),
            if (!_loading && _items.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final a = _items[index];
                  return ListTile(
                    title: Text(a.nome),
                    subtitle: a.horario != null ? Text('Horário: ${a.horario}') : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              final nomeController = TextEditingController(text: a.nome);
                              TimeOfDay? chosenTime;
                              if (a.horario != null && a.horario!.isNotEmpty) {
                                final parts = a.horario!.split(':');
                                if (parts.length >= 2) {
                                  final hh = int.tryParse(parts[0]) ?? 0;
                                  final mm = int.tryParse(parts[1]) ?? 0;
                                  chosenTime = TimeOfDay(hour: hh, minute: mm);
                                }
                              }

                              final saved = await showDialog<bool>(
                                context: context,
                                builder: (context) => StatefulBuilder(builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text('Editar atividade'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Expanded(
                                            child: Text(chosenTime != null ? 'Horário: ${chosenTime?.format(context)}' : 'Sem horário'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final t = await showTimePicker(context: context, initialTime: chosenTime ?? TimeOfDay.now());
                                              if (t != null) setState(() => chosenTime = t);
                                            },
                                            child: const Text('Escolher horário'),
                                          )
                                        ])
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salvar')),
                                    ],
                                  );
                                }),
                              );

                              if (saved == true) {
                                final newNome = nomeController.text.trim();
                                String? horarioString;
                                if (chosenTime != null) {
                                  final hh = chosenTime!.hour.toString().padLeft(2, '0');
                                  final mm = chosenTime!.minute.toString().padLeft(2, '0');
                                  horarioString = '$hh:$mm:00';
                                }

                                try {
                                  final updated = await Supabase.instance.client
                                      .from('atividades')
                                      .update({'nome': newNome, 'horario': horarioString})
                                      .eq('id', a.id!)
                                      .select();
                                  if (updated.isNotEmpty) {
                                    final upd = updated.first as Map<String, dynamic>?;
                                    if (upd != null) {
                                      final atividadeAtualizada = Atividade.fromMap(upd);
                                      if (atividadeAtualizada.horario != null && atividadeAtualizada.id != null) {
                                        await NotificationService().scheduleActivityNotification(atividadeAtualizada);
                                      } else if (atividadeAtualizada.id != null) {
                                        await NotificationService().cancelNotificationForActivityId(atividadeAtualizada.id!);
                                      }
                                    }
                                  }
                                  await _load();
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remover atividade'),
                                  content: const Text('Deseja remover esta atividade?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                    ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  await Supabase.instance.client.from('atividades').delete().eq('id', a.id!).select();
                                  if (a.id != null) await NotificationService().cancelNotificationForActivityId(a.id!);
                                  await _load();
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
