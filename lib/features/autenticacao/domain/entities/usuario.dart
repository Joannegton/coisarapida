/// Entidade que representa um usuário do sistema de aluguel
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final bool emailVerificado;
  final TipoUsuario tipo;
  
  // Campos específicos para aluguel
  final double reputacao;
  final int totalAlugueis;
  final int totalItensAlugados;
  final bool verificado;
  final String? cpf;
  final Endereco? endereco;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    required this.criadoEm,
    this.atualizadoEm,
    required this.emailVerificado,
    required this.tipo,
    this.reputacao = 0.0,
    this.totalAlugueis = 0,
    this.totalItensAlugados = 0,
    this.verificado = false,
    this.cpf,
    this.endereco,
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
    TipoUsuario? tipo,
    double? reputacao,
    int? totalAlugueis,
    int? totalItensAlugados,
    bool? verificado,
    String? cpf,
    Endereco? endereco,
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
      tipo: tipo ?? this.tipo,
      reputacao: reputacao ?? this.reputacao,
      totalAlugueis: totalAlugueis ?? this.totalAlugueis,
      totalItensAlugados: totalItensAlugados ?? this.totalItensAlugados,
      verificado: verificado ?? this.verificado,
      cpf: cpf ?? this.cpf,
      endereco: endereco ?? this.endereco,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum TipoUsuario {
  usuario,
  admin,
}

/// Entidade para endereço do usuário
class Endereco {
  final String cep;
  final String rua;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final double? latitude;
  final double? longitude;

  const Endereco({
    required this.cep,
    required this.rua,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.latitude,
    this.longitude,
  });
}
