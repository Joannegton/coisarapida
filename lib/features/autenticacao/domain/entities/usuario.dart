/// Entidade que representa um usuário do sistema
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
  cliente,
  entregador,
  admin,
}
