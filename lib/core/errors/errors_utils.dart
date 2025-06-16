class ErrorUtils {
  static String tratarErroFirebaseAuth(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Email ou senha incorretos. Verifique seus dados e tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta conta foi desabilitada';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'invalid-credential':
        return 'Email ou senha incorretos. Verifique seus dados e tente novamente.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
        
      default:
        return 'Erro de autenticação: $code';
    }
  }
}
