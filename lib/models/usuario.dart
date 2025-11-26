import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario.freezed.dart';
part 'usuario.g.dart';

DateTime? _dateTimeFromJsonUsuario(dynamic value) {
  if (value == null) return null;
  return DateTime.parse(value as String);
}

String? _dateTimeToJsonUsuario(DateTime? date) => date?.toIso8601String();

@freezed
sealed class Usuario with _$Usuario {
  const factory Usuario({
    int? id,
    @JsonKey(name: 'senha') required String senha,
    @JsonKey(name: 'nome') required String nome,
    @JsonKey(name: 'ativo') bool? ativo,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJsonUsuario, toJson: _dateTimeToJsonUsuario)
        DateTime? createdAt,
    @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJsonUsuario, toJson: _dateTimeToJsonUsuario)
        DateTime? updatedAt,
  }) = _Usuario;

  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);

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
