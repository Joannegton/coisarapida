import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final usuarioAtualStreamProvider = StreamProvider<Usuario?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.usuarioAtual;
});

final idUsuarioAtualProvider = Provider<String?>((ref) {
  return ref.watch(usuarioAtualStreamProvider).value?.id;
});

final usuarioProvider = FutureProvider<Usuario>((ref) async {
  final usuarioAtualProvider = ref.watch(usuarioAtualStreamProvider);
  final usuarioId = usuarioAtualProvider.asData?.value?.id;

  if (usuarioId == null) {
    throw Exception('Usuário não encontrado.');
  }

  final usuario = await ref.watch(authRepositoryProvider).getUsuario(usuarioId);

  if (usuario == null) {
    throw Exception('Usuário não encontrado.');
  }

  return usuario;
});

// Controller para ações de autenticação (login, cadastro, logout, etc.).
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Gerencia o estado e as ações de autenticação.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> loginComEmail({
    required String email,
    required String senha,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.loginComEmail(
        email: email,
        senha: senha,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loginComGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.loginComGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.cadastrarComEmail(
        nome: nome,
        email: email,
        senha: senha,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.enviarEmailRedefinicaoSenha(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> atualizarPerfil({
    String? nome,
    String? telefone,
    String? fotoUrl,
    Endereco? endereco,
    String? cpf,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.atualizarPerfil(
        nome: nome,
        telefone: telefone,
        fotoUrl: fotoUrl,
        endereco: endereco,
        cpf: cpf,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Usuario?> buscarUsuario(String id) async {
    try {
      return await _authRepository.getUsuario(id);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}
