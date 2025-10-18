import 'package:coisarapida/core/providers/notification_provider.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:coisarapida/features/home/presentation/providers/itens_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

/// Gerencia o estado e as ações de autenticação.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref) : super(const AsyncValue.data(null));

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
      
      // Inicializar e salvar FCM token após login
      await _setupNotifications();
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loginComGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.loginComGoogle();
      
      // Inicializar e salvar FCM token após login
      await _setupNotifications();
      
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
      final usuario = await _authRepository.cadastrarComEmail(
        nome: nome,
        email: email,
        senha: senha,
      );
      
      // Inicializar e salvar FCM token após cadastro
      await _setupNotifications(userId: usuario.id);
      
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
      // Remover FCM token antes do logout
      final usuarioAtual = _ref.read(usuarioAtualStreamProvider).value;
      if (usuarioAtual != null) {
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.removeFCMTokenForUser(usuarioAtual.id);
      }
      
      // Invalidar todos os providers relacionados ao usuário antes do logout
      // para evitar erros de permissão do Firestore
      _ref.invalidate(chatsProvider);
      _ref.invalidate(numeroChatsNaoLidosProvider);
      _ref.invalidate(meusAlugueisProvider);
      _ref.invalidate(itensProximosProvider);
      _ref.invalidate(usuarioProvider);
      
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _setupNotifications({String? userId}) async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      final usuarioAtual = userId != null ? null : _ref.read(usuarioAtualStreamProvider).value;
      final uid = userId ?? usuarioAtual?.id;
      if (uid != null) {
        await notificationService.saveFCMTokenForUser(uid);
      }
    } catch (e) {
      // Não falhar o login se houver erro nas notificações
      print('⚠️ Erro ao configurar notificações: $e');
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
