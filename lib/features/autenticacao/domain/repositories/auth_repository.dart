import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';

import '../entities/usuario.dart';

abstract class AuthRepository {
  Stream<Usuario?> get usuarioAtual;

  Future<Usuario> loginComEmail({
    required String email,
    required String senha,
  });

  Future<Usuario> loginComGoogle();

  Future<Usuario> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  });

  Future<void> enviarEmailRedefinicaoSenha(String email);

  Future<void> logout();

  bool get estaLogado;

  Usuario? get usuarioAtualSync;

  Future<void> atualizarPerfil({
    String? nome,
    String? telefone,
    String? fotoUrl,
    Endereco? endereco,
    String? cpf,
  });

  Future<void> excluirConta();

  Future<Usuario?> getUsuario(String uid);
}
