import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';

abstract class ChatRepository {
  Future<void> criarChat({
    required Chat chat,
  });

  Future<Chat?> buscarChat({
    required String usuarioId,
    required String outroUsuarioId,
    required String itemId,
  });

  Future<void> enviarMensagem({
    required String chatId,
    required String userId,
    required String otherUserId,
    required String userDisplayName,
    required String conteudo,
  });

  Future<void> marcarMensagensComoLidas({
    required String chatId,
    required String userId,
    required String outroUserId,
  });

  Stream<List<Chat>> getChatsStream(String userId);

  Stream<List<Mensagem>> getMessagesStream(String chatId);

  Future<Chat?> getChatDetails(String chatId);
}