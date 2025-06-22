import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:coisarapida/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl(this._firestore);

  @override
  Future<void> criarChat({
    required Chat chat,
  }) async {
    await _firestore.collection('chats').doc(chat.id).set(chat.toMap());
  }

  @override
  Future<Chat?> buscarChat({required String usuarioId, required String outroUsuarioId}) async {
    List<String> ids = [usuarioId, outroUsuarioId];
    ids.sort();
    String chatId = '${ids[0]}_${ids[1]}';

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (chatDoc.exists) {
      return Chat.fromFirestore(chatDoc);
    }
    return null;
  }

  @override
  Future<void> enviarMensagem({
    required String chatId,
    required String userId,
    required String userDisplayName,
    required String conteudo,
  }) async {
    final mensagemId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
    final novaMensagem = Mensagem(
      id: mensagemId,
      chatId: chatId,
      remetenteId: userId,
      remetenteNome: userDisplayName,
      conteudo: conteudo,
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(mensagemId)
        .set(novaMensagem.toMap());

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data();
      if (data == null) return;

      final String locadorId = data['locadorId'];
      final String locatarioId = data['locatarioId'];
      final String outroUserId = (locadorId == userId) ? locatarioId : locadorId;

      await _firestore.collection('chats').doc(chatId).update({
        'ultimaMensagem': novaMensagem.toMap(),
        'atualizadoEm': FieldValue.serverTimestamp(),
        'mensagensNaoLidas.$outroUserId': FieldValue.increment(1),
      });
    }
  }

  @override
  Future<void> marcarMensagensComoLidas({
    required String chatId,
    required String userId,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;
    final data = chatDoc.data();
    if (data == null) return;

    final String locadorId = data['locadorId'];
    final String locatarioId = data['locatarioId'];
    final String outroUserId = (locadorId == userId) ? locatarioId : locadorId;

    final unreadMessagesQuery = chatRef
        .collection('messages')
        .where('remetenteId', isEqualTo: outroUserId)
        .where('lida', isEqualTo: false)
        .get();

    final results = await Future.wait([
      chatRef.update({
        'mensagensNaoLidas.$userId': 0,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }),
      unreadMessagesQuery,
    ]);

    final unreadMessagesSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    if (unreadMessagesSnapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadMessagesSnapshot.docs) {
      batch.update(doc.reference, {'lida': true});
    }
    await batch.commit();
  }
}