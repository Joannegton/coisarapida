import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usuario.dart';

/// Model para serialização/deserialização do usuário
class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.nome,
    required super.email,
    super.telefone,
    super.fotoUrl,
    required super.criadoEm,
    super.atualizadoEm,
    required super.emailVerificado,
    required super.tipo,
  });

  /// Criar UsuarioModel a partir de Map
  factory UsuarioModel.fromMap(Map<String, dynamic> map, String id) {
    return UsuarioModel(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'],
      fotoUrl: map['fotoUrl'],
      criadoEm: (map['criadoEm'] as Timestamp).toDate(),
      atualizadoEm: map['atualizadoEm'] != null
          ? (map['atualizadoEm'] as Timestamp).toDate()
          : null,
      emailVerificado: map['emailVerificado'] ?? false,
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoUsuario.cliente,
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
      'criadoEm': Timestamp.fromDate(criadoEm),
      'atualizadoEm': atualizadoEm != null 
          ? Timestamp.fromDate(atualizadoEm!) 
          : null,
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
