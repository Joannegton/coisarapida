/// Enum que representa o status de verificação do endereço do usuário
enum StatusEndereco {
  /// Endereço aprovado pela administração
  aprovado,
  
  /// Endereço em análise pela administração
  emAnalise,
  
  /// Endereço reprovado pela administração
  rejeitado;

  /// Converte string para enum
  static StatusEndereco? fromString(String? value) {
    if (value == null) return null;
    
    switch (value) {
      case 'aprovado':
        return StatusEndereco.aprovado;
      case 'em_analise':
        return StatusEndereco.emAnalise;
      case 'rejeitado':
        return StatusEndereco.rejeitado;
      default:
        return null;
    }
  }

  /// Converte enum para string (formato Firestore)
  String toFirestore() {
    switch (this) {
      case StatusEndereco.aprovado:
        return 'aprovado';
      case StatusEndereco.emAnalise:
        return 'em_analise';
      case StatusEndereco.rejeitado:
        return 'reprovado';
    }
  }

  /// Verifica se o usuário pode realizar ações restritas (alugar, comprar, vender, enviar mensagens)
  bool get podeRealizarAcoes => this == StatusEndereco.aprovado;

  /// Verifica se o usuário pode acessar a home (aprovado ou em análise)
  bool get podeAcessarHome => this == StatusEndereco.aprovado || this == StatusEndereco.emAnalise;
}
