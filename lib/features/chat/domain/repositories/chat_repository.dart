import 'package:coisarapida/features/chat/domain/entities/chat.dart';

abstract class ChatRepository {
  Future<void> criarChat({
    required Chat chat,
  });

  Future<Chat?> buscarChat({
    required String usuarioId,
    required String outroUsuarioId,
  });
  Future<void> enviarMensagem({
    required String chatId,
    required String userId,
    required String userDisplayName,
    required String conteudo,
  });

  Future<void> marcarMensagensComoLidas({
    required String chatId,
    required String userId,
  });
}