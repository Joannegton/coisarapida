import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/entities/endereco.dart';

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
    super.reputacao,
    super.totalAlugueis,
    super.totalItensAlugados,
    super.verificado,
    super.cpf,
    super.endereco,
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
      reputacao: (map['reputacao'] as num?)?.toDouble() ?? 0.0,
      totalAlugueis: map['totalAlugueis'] as int? ?? 0,
      totalItensAlugados: map['totalItensAlugados'] as int? ?? 0,
      verificado: map['verificado'] as bool? ?? false,
      cpf: map['cpf'] as String?,
      endereco: map['endereco'] != null ? EnderecoModel.fromMap(map['endereco']) : null,
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
      'reputacao': reputacao,
      'totalAlugueis': totalAlugueis,
      'totalItensAlugados': totalItensAlugados,
      'verificado': verificado,
      'cpf': cpf,
      'endereco': (endereco as EnderecoModel?)?.toMap(),
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
      tipo: usuario.tipo,
      reputacao: usuario.reputacao,
      totalAlugueis: usuario.totalAlugueis,
      totalItensAlugados: usuario.totalItensAlugados,
      verificado: usuario.verificado,
      cpf: usuario.cpf,
      endereco: usuario.endereco != null ? EnderecoModel.fromEntity(usuario.endereco!) : null,
    );
  }
}

// Modelo para Endereco para serialização com Firestore
class EnderecoModel extends Endereco {
  const EnderecoModel({
    required super.cep,
    required super.rua,
    required super.numero,
    super.complemento,
    required super.bairro,
    required super.cidade,
    required super.estado,
    super.latitude,
    super.longitude,
  });

  factory EnderecoModel.fromMap(Map<String, dynamic> map) {
    return EnderecoModel(
      cep: map['cep'] ?? '',
      rua: map['rua'] ?? '',
      numero: map['numero'] ?? '',
      complemento: map['complemento'],
      bairro: map['bairro'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EnderecoModel.fromEntity(Endereco entity) {
    return EnderecoModel(
        cep: entity.cep, rua: entity.rua, numero: entity.numero, complemento: entity.complemento, bairro: entity.bairro, cidade: entity.cidade, estado: entity.estado, latitude: entity.latitude, longitude: entity.longitude);
  }
}
