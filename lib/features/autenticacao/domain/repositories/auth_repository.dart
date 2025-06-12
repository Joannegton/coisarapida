import '../entities/usuario.dart';

/// Interface para operações de autenticação
abstract class AuthRepository {
  /// Stream do usuário atual
  Stream<Usuario?> get usuarioAtual;

  /// Fazer login com email e senha
  Future<Usuario> loginComEmail({
    required String email,
    required String senha,
  });

  /// Fazer login com Google
  Future<Usuario> loginComGoogle();

  /// Cadastrar novo usuário
  Future<Usuario> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  });

  /// Enviar email de redefinição de senha
  Future<void> enviarEmailRedefinicaoSenha(String email);

  /// Fazer logout
  Future<void> logout();

  /// Verificar se usuário está logado
  bool get estaLogado;

  /// Obter usuário atual
  Usuario? get usuarioAtualSync;

  /// Atualizar perfil do usuário
  Future<void> atualizarPerfil({
    String? nome,
    String? telefone,
    String? fotoUrl,
  });

  /// Excluir conta
  Future<void> excluirConta();
}
