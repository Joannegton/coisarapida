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
  Future<Chat?> buscarChat({required String usuarioId, required String outroUsuarioId, required String itemId}) async {
    final chatId = Chat.generateChatId(userId1: usuarioId, userId2: outroUsuarioId, itemId: itemId);

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
    required String otherUserId,
    required String userDisplayName,
    required String conteudo,
  }) async {
    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final novaMensagem = Mensagem(
      id: messageRef.id,
      chatId: chatId,
      remetenteId: userId,
      remetenteNome: userDisplayName,
      conteudo: conteudo,
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now(),
    );

    // 1. Adiciona a nova mensagem em um batch
    batch.set(messageRef, novaMensagem.toMap());

    // 2. Atualiza o documento do chat no mesmo batch
    batch.update(chatRef, {
      'ultimaMensagem': novaMensagem.toMap(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'mensagensNaoLidas.$otherUserId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> marcarMensagensComoLidas({
    required String chatId,
    required String userId,
    required String outroUserId,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final batch = _firestore.batch();
    
    batch.update(chatRef, {
      'mensagensNaoLidas.$userId': 0,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    final unreadMessagesSnapshot = await chatRef
        .collection('messages')
        .where('remetenteId', isEqualTo: outroUserId)
        .where('lida', isEqualTo: false)
        .get();

    if (unreadMessagesSnapshot.docs.isNotEmpty) {
      for (final doc in unreadMessagesSnapshot.docs) {
        batch.update(doc.reference, {'lida': true});
      }
    }


    await batch.commit();
  }

  @override
  Stream<List<Chat>> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participantes', arrayContains: userId)
        .orderBy('atualizadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<Mensagem>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('enviadaEm', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Mensagem.fromFirestore(doc)).toList());
  }

  @override
  Future<Chat?> getChatDetails(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.exists ? Chat.fromFirestore(doc) : null;
  }
}