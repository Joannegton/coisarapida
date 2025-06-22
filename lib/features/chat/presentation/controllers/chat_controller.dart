import 'package:coisarapida/features/chat/data/repositories/chat_repository_impl.dart'; // Updated import
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _auth = FirebaseAuth.instance;

/// TODO Provider para controlar o envio de mensagens 
final chatControllerProvider = StateNotifierProvider.autoDispose<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref); 
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ChatController(this._ref) : super(const AsyncValue.data(null));

  Future<void> criarChat(Chat chat) async {
    state = const AsyncValue.loading();
    final usuarioId = _ref.read(idUsuarioAtualProvider);
    final usuario = _auth.currentUser;

    if (usuarioId == null || usuario == null) {
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
    }

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.criarChat(chat: chat);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Chat?> buscarChat({required String currentUserId, required String otherUserId}) async {
    final repository = _ref.read(chatRepositoryProvider);
    return await repository.buscarChat(usuarioId: currentUserId, outroUsuarioId: otherUserId);
  }


  Future<void> enviarMensagem(String chatId, String conteudo) async {
    state = const AsyncValue.loading();
    final userId = _ref.read(idUsuarioAtualProvider);
    final user = _auth.currentUser;

    if (userId == null || user == null) {
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return;
    }

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.enviarMensagem(
        chatId: chatId,
        userId: userId,
        userDisplayName: user.displayName ?? 'Usuário Anônimo',
        conteudo: conteudo,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> marcarMensagensComoLidas(String chatId) async {
    final userId = _ref.read(idUsuarioAtualProvider);
    if (userId == null) return;

    try {
      final repository = _ref.read(chatRepositoryProvider);
      await repository.marcarMensagensComoLidas(
        chatId: chatId,
        userId: userId,
      );
    } catch (e) {
      print('Erro ao marcar mensagens como lidas: $e');
    }
  }
}