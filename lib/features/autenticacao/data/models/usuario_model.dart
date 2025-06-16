import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usuario.dart';

/// Model para serialização/deserialização do usuário
class UsuarioModel extends Usuario {
  // Campos para armazenar o input original, que pode ser DateTime ou FieldValue
  final dynamic _criadoEmInput;
  final dynamic _atualizadoEmInput;

  UsuarioModel({
    required super.id,
    required super.nome,
    required super.email,
    super.telefone,
    super.fotoUrl,
    required dynamic criadoEm, // Aceita DateTime ou FieldValue.serverTimestamp()
    dynamic atualizadoEm,   // Aceita DateTime, FieldValue.serverTimestamp() ou null
    required super.emailVerificado,
    required super.tipo,
  })  : _criadoEmInput = criadoEm,
        _atualizadoEmInput = atualizadoEm,
        super(
          // Para a entidade Usuario (super), sempre passamos DateTime.
          // Se o input for FieldValue, usamos DateTime.now() como um placeholder temporário.
          // Após salvar e ler do Firestore, este campo será o DateTime correto do servidor.
          criadoEm: criadoEm is DateTime ? criadoEm : DateTime.now(),
          atualizadoEm: atualizadoEm is DateTime
              ? atualizadoEm
              : (atualizadoEm == null ? null : DateTime.now())
        );

  /// Criar UsuarioModel a partir de Map
  factory UsuarioModel.fromMap(Map<String, dynamic> map, String id) {
    // Ao ler do Firestore, 'criadoEm' e 'atualizadoEm' serão Timestamps.
    // Convertemos para DateTime para o construtor do UsuarioModel.
    final dateTimeCriadoEm = (map['criadoEm'] as Timestamp).toDate();
    final dateTimeAtualizadoEm = map['atualizadoEm'] != null
        ? (map['atualizadoEm'] as Timestamp).toDate()
        : null;

    return UsuarioModel(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'],
      fotoUrl: map['fotoUrl'],
      criadoEm: dateTimeCriadoEm, // Passa o DateTime convertido
      atualizadoEm: dateTimeAtualizadoEm, // Passa o DateTime? convertido
      emailVerificado: map['emailVerificado'] ?? false,
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoUsuario.usuario,
      ),
    );
  }

  /// Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      // Usa o input original. Se for FieldValue, usa diretamente.
      // Se for DateTime (ex: vindo de fromMap ou passado explicitamente), converte para Timestamp.
      'criadoEm': _criadoEmInput is FieldValue
          ? _criadoEmInput
          : Timestamp.fromDate(_criadoEmInput as DateTime),
      'atualizadoEm': _atualizadoEmInput is FieldValue
          ? _atualizadoEmInput
          : (_atualizadoEmInput == null
              ? null
              : Timestamp.fromDate(_atualizadoEmInput as DateTime)),
      'emailVerificado': emailVerificado,
      'tipo': tipo.name,
    };
  }

  /// Converter para entidade
  Usuario toEntity() {
    return Usuario(
      id: id,
      nome: nome,
      email: email,
      telefone: telefone,
      fotoUrl: fotoUrl,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
      emailVerificado: emailVerificado,
      tipo: tipo,
    );
  }

  /// Criar UsuarioModel a partir de entidade
  factory UsuarioModel.fromEntity(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      telefone: usuario.telefone,
      fotoUrl: usuario.fotoUrl,
      criadoEm: usuario.criadoEm,
      atualizadoEm: usuario.atualizadoEm,
      emailVerificado: usuario.emailVerificado,
      tipo: usuario.tipo,
    );
  }
}
