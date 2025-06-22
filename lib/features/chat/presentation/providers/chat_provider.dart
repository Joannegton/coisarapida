import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:coisarapida/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(FirebaseFirestore.instance);
});

final chatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final userId = ref.watch(idUsuarioAtualProvider);
  if (userId == null) return Stream.value([]);
  
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatsStream(userId);
});

final mensagensChatProvider = StreamProvider.autoDispose.family<List<Mensagem>, String>((ref, chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessagesStream(chatId);
});

final chatDetailsProvider = FutureProvider.autoDispose.family<Chat?, String>((ref, chatId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatDetails(chatId);
});

final numeroChatsNaoLidosProvider = Provider.autoDispose<int>((ref) {
  final usuarioId = ref.watch(idUsuarioAtualProvider);
  if (usuarioId == null) {
    return 0;
  }

  final chatsAsyncValue = ref.watch(chatsProvider);

  // Quando os dados estiverem disponíveis, filtra os chats com mensagens não lidas e retorna a contagem.
  return chatsAsyncValue.when(
    data: (chats) => chats.where((chat) => (chat.mensagensNaoLidas[usuarioId] ?? 0) > 0).length,
    loading: () => 0, // Retorna 0 enquanto carrega ou em caso de erro
    error: (_, __) => 0,
  );
});
