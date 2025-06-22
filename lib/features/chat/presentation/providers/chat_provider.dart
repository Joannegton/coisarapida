import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

final chatRepositoryProvider = Provider<ChatRepositoryImpl>((ref) {
  return ChatRepositoryImpl(FirebaseFirestore.instance);
});

/// Provider que expõe o stream de mudanças de estado de autenticação do Firebase.
/// Este é o "coração" da reatividade da autenticação em todo o app.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return _auth.authStateChanges();
});

/// Provider que expõe o ID do usuário atualmente logado.
/// Ele observa o `authStateChangesProvider` e extrai o UID, tornando-se reativo.
final idUsuarioAtualProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).value?.uid;
});

/// Provider para lista de chats do usuário (Stream)
final chatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final userId = ref.watch(idUsuarioAtualProvider);
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
final mensagensChatProvider = StreamProvider.autoDispose.family<List<Mensagem>, String>((ref, chatId) {
  return _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('enviadaEm', descending: false) // Mais antigas primeiro
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Mensagem.fromFirestore(doc)).toList());
});

/// Provider para buscar detalhes de um chat específico.
final chatDetailsProvider = FutureProvider.autoDispose.family<Chat?, String>((ref, chatId) async {
  final doc = await _firestore.collection('chats').doc(chatId).get();
  if (doc.exists) {
    return Chat.fromFirestore(doc);
  }
  return null;
});

final numeroChatsNaoLidosProvider = Provider.autoDispose<int>((ref) {
  final usuarioId = ref.watch(idUsuarioAtualProvider);
  if (usuarioId == null) {
    return 0;
  }

  // Observa o provider principal de chats
  final chatsAsyncValue = ref.watch(chatsProvider);

  // Quando os dados estiverem disponíveis, filtra os chats com mensagens não lidas e retorna a contagem.
  return chatsAsyncValue.when(
    data: (chats) => chats.where((chat) => (chat.mensagensNaoLidas[usuarioId] ?? 0) > 0).length,
    loading: () => 0, // Retorna 0 enquanto carrega ou em caso de erro
    error: (_, __) => 0,
  );
});
