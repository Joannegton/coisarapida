import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

// Provider do repositório de autenticação
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

// Provider do estado de autenticação (stream)
final authStateProvider = StreamProvider<Usuario?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.usuarioAtual;
});

// Provider para operações de autenticação
final authControllerProvider = 
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Controller para gerenciar operações de autenticação
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  /// Fazer login com email e senha
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

  /// Fazer login com Google
  Future<void> loginComGoogle() async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.loginComGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Cadastrar novo usuário
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

  /// Enviar email de redefinição de senha
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.enviarEmailRedefinicaoSenha(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Fazer logout
  Future<void> logout() async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Atualizar perfil
  Future<void> atualizarPerfil({
    String? nome,
    String? telefone,
    String? fotoUrl,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authRepository.atualizarPerfil(
        nome: nome,
        telefone: telefone,
        fotoUrl: fotoUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
