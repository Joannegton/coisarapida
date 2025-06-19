import 'dart:async';
import 'package:coisarapida/core/errors/errors_utils.dart';
import 'package:coisarapida/features/autenticacao/data/models/endereco_model.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/usuario_model.dart';
import '../../../../core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<Usuario?> get usuarioAtual {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      try {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (!doc.exists) return null;
        
        return UsuarioModel.fromMap(doc.data()!, doc.id);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<Usuario> loginComEmail({
    required String email,
    required String senha,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (credential.user == null) {
        throw const AuthException('Falha na autenticação');
      }

      return await _obterUsuarioFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(ErrorUtils.tratarErroFirebaseAuth(e.code));
    } catch (e) {
      throw AuthException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Usuario> loginComGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Login cancelado pelo usuário');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw const AuthException('Falha na autenticação com Google');
      }

      final doc = await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        await _criarUsuarioFirestore(
          userCredential.user!,
          userCredential.user!.displayName ?? 'Usuário',
        );
      }

      return await _obterUsuarioFirestore(userCredential.user!.uid);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erro no login com Google: ${e.toString()}');
    }
  }

  @override
  Future<Usuario> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (credential.user == null) {
        throw const AuthException('Falha ao criar conta');
      }

      // atualizar nome do usuário no Firebase Auth
      await credential.user!.updateDisplayName(nome);

      await _criarUsuarioFirestore(credential.user!, nome);

      await credential.user!.sendEmailVerification();

      return await _obterUsuarioFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(ErrorUtils.tratarErroFirebaseAuth(e.code));
    } catch (e) {
      throw AuthException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(ErrorUtils.tratarErroFirebaseAuth(e.code));
    } catch (e) {
      throw AuthException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Erro ao fazer logout: ${e.toString()}');
    }
  }

  @override
  bool get estaLogado => _firebaseAuth.currentUser != null;

  @override
  Usuario? get usuarioAtualSync {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    
    // Retorna dados básicos do Firebase Auth
    return Usuario(
      id: user.uid,
      nome: user.displayName ?? 'Usuário',
      email: user.email ?? '',
      fotoUrl: user.photoURL,
      criadoEm: user.metadata.creationTime ?? DateTime.now(),
      emailVerificado: user.emailVerified,
    );
  }

  @override
  Future<void> atualizarPerfil({
    String? nome,
    String? telefone,
    String? fotoUrl,
    Endereco? endereco,
    String? cpf,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw const AuthException('Usuário não autenticado');

      final updates = <String, dynamic>{
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (nome != null) {
        updates['nome'] = nome;
        await user.updateDisplayName(nome);
      }

      if (telefone != null) {
        updates['telefone'] = telefone;
      }

      if (fotoUrl != null) {
        updates['fotoUrl'] = fotoUrl;
        await user.updatePhotoURL(fotoUrl);
      }

      if (endereco != null) {
        updates['endereco'] = EnderecoModel.fromEntity(endereco).toMap();
      }

      if (cpf != null) {
        updates['cpf'] = cpf;
      }

      await _firestore.collection('usuarios').doc(user.uid).update(updates);
    } catch (e) {
      throw AuthException('Erro ao atualizar perfil: ${e.toString()}');
    }
  }

  @override
  Future<void> excluirConta() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw const AuthException('Usuário não autenticado');

      await _firestore.collection('usuarios').doc(user.uid).delete();

      await user.delete();
    } catch (e) {
      throw AuthException('Erro ao excluir conta: ${e.toString()}');
    }
  }

  @override
  Future<Usuario?> getUsuario(String uid) async {
    try {
      return await _obterUsuarioFirestore(uid);
    } catch (e) {
      return null;
    }
  }

  // Métodos auxiliares
  Future<Usuario> _obterUsuarioFirestore(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    
    if (!doc.exists) {
      throw const AuthException('Dados do usuário não encontrados');
    }

    return UsuarioModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> _criarUsuarioFirestore(User user, String nome) async {
    final usuarioModel = UsuarioModel(
      id: user.uid,
      nome: nome,
      email: user.email!,
      fotoUrl: user.photoURL,
      criadoEm: FieldValue.serverTimestamp(),
      atualizadoEm: FieldValue.serverTimestamp(),
      emailVerificado: user.emailVerified,
    );

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .set(usuarioModel.toMap());
  }
}
