class Atividade {
  final int? id;
  final String nome;
  final String? horario; 
  final DateTime? createdAt;

  Atividade({this.id, required this.nome, this.horario, this.createdAt});

  factory Atividade.fromMap(Map<String, dynamic> m) {
    DateTime? created;
    if (m['created_at'] != null) {
      try {
        created = DateTime.parse(m['created_at'] as String);
      } catch (_) {
        created = null;
      }
    }
    return Atividade(
      id: (m['id'] is int) ? m['id'] as int : (m['id'] is num ? (m['id'] as num).toInt() : null),
      nome: m['nome'] as String? ?? '',
      horario: m['horario'] as String?,
      createdAt: created,
    );
  }
}
