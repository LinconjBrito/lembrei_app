import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario.freezed.dart';

DateTime? _dateTimeFromJsonUsuario(dynamic value) {
  if (value == null) return null;
  return DateTime.parse(value as String);
}

@freezed
sealed class Usuario with _$Usuario {
  const factory Usuario({
    int? id,
    required String senha,
    required String nome,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Usuario;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int?,
      senha: json['senha'] as String,
      nome: json['nome'] as String,
      ativo: json['ativo'] as bool?,
      createdAt: _dateTimeFromJsonUsuario(json['created_at']),
      updatedAt: _dateTimeFromJsonUsuario(json['updated_at']),
    );
  }

  factory Usuario.fromDocument(Map<String, dynamic> doc) {
    return Usuario.fromJson(Map<String, dynamic>.from(doc));
  }

  factory Usuario.empty() => const Usuario(
        id: null,
        senha: '',
        nome: '',
        ativo: null,
        createdAt: null,
        updatedAt: null,
      );
}
