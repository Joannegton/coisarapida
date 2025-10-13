import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final _auth = FirebaseAuth.instance;

final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref); 
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ChatController(this._ref) : super(const AsyncValue.data(null));

  //TODO melhorar
  Future<String> abrirOuCriarChat({
    required Usuario usuarioAtual,
    required Item item,
  }) async {
    final currentUserId = usuarioAtual.id;
    final proprietarioId = item.proprietarioId;
    final repository = _ref.read(chatRepositoryProvider);

    final chatExistente = await repository.buscarChat(usuarioId: currentUserId, outroUsuarioId: proprietarioId, itemId: item.id);

    if (chatExistente != null) {
      return chatExistente.id;
    }

    final proprietarioUser = await _ref.read(authControllerProvider.notifier).buscarUsuario(item.proprietarioId);

    if (!_ref.mounted) return '';

    final chatId = Chat.generateChatId(userId1: currentUserId, userId2: proprietarioId, itemId: item.id);

    final chat = Chat(
      id: chatId,
      itemId: item.id,
      itemNome: item.nome,
      itemFoto: item.fotos.isNotEmpty ? item.fotos.first : '',
      locadorId: proprietarioUser!.id,
      locadorNome: proprietarioUser.nome,
      locadorFoto: proprietarioUser.fotoUrl ?? '',
      locatarioId: currentUserId,
      locatarioNome: usuarioAtual.nome,
      locatarioFoto: usuarioAtual.fotoUrl ?? '',
      criadoEm: DateTime.now(),
    );
    
    await _criarChat(chat);
    
    if (!_ref.mounted) return '';
    
    return chatId;
  }

  Future<void> _criarChat(Chat chat) async {
    final usuarioId = _ref.read(idUsuarioAtualProvider);
    final usuario = _auth.currentUser;

    if (usuarioId == null || usuario == null) {
      if (!_ref.mounted) return;
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return;
    }

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.criarChat(chat: chat);
      if (!_ref.mounted) return;
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      if (!_ref.mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> enviarMensagem(String chatId, String otherUserId, String conteudo) async {
    state = const AsyncValue.loading();
    final userId = _ref.read(idUsuarioAtualProvider);
    final user = _auth.currentUser;

    if (userId == null || user == null) {
      if (!_ref.mounted) return;
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return;
    }

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.enviarMensagem(
        chatId: chatId,
        userId: userId,
        otherUserId: otherUserId,
        userDisplayName: user.displayName ?? 'Usuário Anônimo',
        conteudo: conteudo,
      );
      if (!_ref.mounted) return;
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      if (!_ref.mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> marcarMensagensComoLidas(String chatId, String outroUsuarioId) async {
    final userId = _ref.read(idUsuarioAtualProvider);
    if (userId == null) return;

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.marcarMensagensComoLidas(
        chatId: chatId,
        userId: userId,
        outroUserId: outroUsuarioId
      );
      if (!_ref.mounted) return;
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }
}