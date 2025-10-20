import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/autenticacao/data/models/endereco_model.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import '../../domain/entities/usuario.dart';

/// Model para serialização/deserialização do usuário
class UsuarioModel extends Usuario {
  // input original, que pode ser DateTime ou FieldValue
  final dynamic _criadoEmInput;
  final dynamic _atualizadoEmInput;

  UsuarioModel({
    required super.id,
    required super.nome,
    required super.email,
    super.telefone,
    super.fotoUrl,
    required dynamic criadoEm,
    dynamic atualizadoEm,   
    required super.emailVerificado,
    super.reputacao,
    super.totalAlugueis,
    super.totalItensAlugados,
    super.verificado,
    super.cpf,
    super.endereco,
    super.statusEndereco,
  })  : _criadoEmInput = criadoEm,
        _atualizadoEmInput = atualizadoEm,
        super(
          criadoEm: criadoEm is DateTime ? criadoEm : DateTime.now(),
          atualizadoEm: atualizadoEm is DateTime
              ? atualizadoEm
              : (atualizadoEm == null ? null : DateTime.now())
        );

  /// Criar UsuarioModel a partir de Map
  factory UsuarioModel.fromMap(Map<String, dynamic> map, String id) {
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
      criadoEm: dateTimeCriadoEm, 
      atualizadoEm: dateTimeAtualizadoEm,
      emailVerificado: map['emailVerificado'] ?? false,
      reputacao: (map['reputacao'] as num?)?.toDouble() ?? 0.0,
      totalAlugueis: map['totalAlugueis'] as int? ?? 0,
      totalItensAlugados: map['totalItensAlugados'] as int? ?? 0,
      verificado: map['verificado'] as bool? ?? false,
      cpf: map['cpf'] as String?,
      endereco: map['endereco'] != null ? EnderecoModel.fromMap(map['endereco']) : null,
      statusEndereco: StatusEndereco.fromString(map['statusEndereco'] as String?),
    );
  }

  /// Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'criadoEm': _criadoEmInput is FieldValue
          ? _criadoEmInput
          : Timestamp.fromDate(_criadoEmInput as DateTime),
      'atualizadoEm': _atualizadoEmInput is FieldValue
          ? _atualizadoEmInput
          : (_atualizadoEmInput == null
              ? null
              : Timestamp.fromDate(_atualizadoEmInput as DateTime)),
      'emailVerificado': emailVerificado,
      'reputacao': reputacao,
      'totalAlugueis': totalAlugueis,
      'totalItensAlugados': totalItensAlugados,
      'verificado': verificado,
      'cpf': cpf,
      'endereco': (endereco as EnderecoModel?)?.toMap(),
      'statusEndereco': statusEndereco?.toFirestore(),
    };
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
      reputacao: usuario.reputacao,
      totalAlugueis: usuario.totalAlugueis,
      totalItensAlugados: usuario.totalItensAlugados,
      verificado: usuario.verificado,
      cpf: usuario.cpf,
      endereco: usuario.endereco != null ? EnderecoModel.fromEntity(usuario.endereco!) : null,
      statusEndereco: usuario.statusEndereco,
    );
  }
}