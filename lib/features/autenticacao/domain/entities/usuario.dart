import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final bool emailVerificado;
  
  // Campos específicos para aluguel
  final double reputacao;
  final int totalAlugueis;
  final int totalItensAlugados;
  final bool verificado;
  final String? cpf;
  final Endereco? endereco;
  
  // Campos de verificação
  final bool telefoneVerificado;
  final bool enderecoVerificado;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    required this.criadoEm,
    this.atualizadoEm,
    required this.emailVerificado,
    this.reputacao = 0.0,
    this.totalAlugueis = 0,
    this.totalItensAlugados = 0,
    this.verificado = false,
    this.cpf,
    this.endereco,
    this.telefoneVerificado = false,
    this.enderecoVerificado = false,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    bool? emailVerificado,
    double? reputacao,
    int? totalAlugueis,
    int? totalItensAlugados,
    bool? verificado,
    String? cpf,
    Endereco? endereco,
    bool? telefoneVerificado,
    bool? enderecoVerificado,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      reputacao: reputacao ?? this.reputacao,
      totalAlugueis: totalAlugueis ?? this.totalAlugueis,
      totalItensAlugados: totalItensAlugados ?? this.totalItensAlugados,
      verificado: verificado ?? this.verificado,
      cpf: cpf ?? this.cpf,
      endereco: endereco ?? this.endereco,
      telefoneVerificado: telefoneVerificado ?? this.telefoneVerificado,
      enderecoVerificado: enderecoVerificado ?? this.enderecoVerificado,
    );
  }

   // sobrescrita do operador de igualdade (==)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Se for a mesma instância na memória
    return other is Usuario && other.id == id; // Se for do tipo Usuario e tiver o mesmo id
  }

  // sobrescrita do hashCode (geralmente sobrescrito junto com o ==)
  @override
  int get hashCode => id.hashCode; // O hashCode é baseado no id
}