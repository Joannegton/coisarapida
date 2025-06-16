import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

/// Provider para o ID do usuário atual (mockado, substituir por Firebase Auth real)
/// Em um app real, você usaria o provider de autenticação do Firebase.
final currentUserIdProvider = Provider<String?>((ref) {
  return _auth.currentUser?.uid;
});

/// Provider para lista de chats do usuário (Stream)
final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]); // Retorna lista vazia se não houver usuário logado
  }

  return _firestore
      .collection('chats')
      .where('participantes', arrayContains: userId)
      .orderBy('atualizadoEm', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
});

/// Provider para mensagens de um chat específico (Stream)
final mensagensChatProvider = StreamProvider.family<List<Mensagem>, String>((ref, chatId) {
  return _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('enviadaEm', descending: false) // Mais antigas primeiro
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Mensagem.fromFirestore(doc)).toList());
});

/// Provider para buscar detalhes de um chat específico.
final chatDetailsProvider = FutureProvider.family<Chat?, String>((ref, chatId) async {
  final doc = await _firestore.collection('chats').doc(chatId).get();
  if (doc.exists) {
    return Chat.fromFirestore(doc);
  }
  return null;
});

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
      
      // Identificar o ID do outro usuário para incrementar mensagensNãoLidas
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = Chat.fromFirestore(chatDoc);
        String outroUserId;
        if (chatData.locadorId == userId) {
          outroUserId = chatData.locatarioId;
        } else {
          outroUserId = chatData.locadorId;
        }

        // Atualizar o documento do chat com a última mensagem, timestamp e mensagens não lidas
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
