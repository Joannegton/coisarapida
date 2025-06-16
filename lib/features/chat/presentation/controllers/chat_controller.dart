import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

/// Provider para controlar o envio de mensagens
final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref);
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ChatController(this._ref) : super(const AsyncValue.data(null));

  Future<void> enviarMensagem(String chatId, String conteudo) async {
    state = const AsyncValue.loading();
    final userId = _ref.read(currentUserIdProvider);
    final user = _auth.currentUser;

    if (userId == null || user == null) {
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return;
    }

    try {
      final mensagemId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
      final novaMensagem = Mensagem(
        id: mensagemId,
        chatId: chatId,
        remetenteId: userId,
        remetenteNome: user.displayName ?? 'Usuário Anônimo', // Ou buscar de um perfil
        conteudo: conteudo,
        tipo: TipoMensagem.texto,
        enviadaEm: DateTime.now(),
      );

      // Escrever a mensagem na subcoleção
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(mensagemId)
          .set(novaMensagem.toMap());
      
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = Chat.fromFirestore(chatDoc);
        String outroUserId = (chatData.locadorId == userId) ? chatData.locatarioId : chatData.locadorId;

        await _firestore.collection('chats').doc(chatId).update({
          'ultimaMensagem': novaMensagem.toMap(),
          'atualizadoEm': FieldValue.serverTimestamp(),
          'mensagensNaoLidas.$outroUserId': FieldValue.increment(1),
        });
      }
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}