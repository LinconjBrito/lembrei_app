class Atividade {
  final int? id;
  final String nome;
  final String? horario; 
  final bool recorrente;
  final bool concluida;
  final DateTime? dataconclusao;
  final DateTime? createdAt;

  Atividade({
    this.id,
    required this.nome,
    this.horario,
    this.recorrente = false,
    this.concluida = false,
    this.dataconclusao,
    this.createdAt,
  });

  factory Atividade.fromMap(Map<String, dynamic> m) {
    DateTime? created;
    if (m['created_at'] != null) {
      try {
        created = DateTime.parse(m['created_at'] as String);
      } catch (_) {
        created = null;
      }
    }
    DateTime? dataConclusao;
    if (m['data_conclusao'] != null) {
      try {
        dataConclusao = DateTime.parse(m['data_conclusao'] as String);
      } catch (_) {
        dataConclusao = null;
      }
    }
    
    return Atividade(
      id: (m['id'] is int) ? m['id'] as int : (m['id'] is num ? (m['id'] as num).toInt() : null),
      nome: m['nome'] as String? ?? '',
      horario: m['horario'] as String?,
      recorrente: m['recorrente'] == true,
      concluida: m['concluida'] == true,
      dataconclusao: dataConclusao,
      createdAt: created,
    );
  }
}
