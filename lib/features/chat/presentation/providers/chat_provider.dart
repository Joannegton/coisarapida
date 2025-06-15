import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para lista de chats do usuário
final chatsProvider = FutureProvider<List<Chat>>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Dados mockados de chats
  return [
    Chat(
      id: 'chat1',
      itemId: '1',
      itemNome: 'Furadeira Bosch',
      itemFoto: 'https://via.placeholder.com/100x100?text=Furadeira',
      locadorId: 'user1',
      locadorNome: 'João Silva',
      locadorFoto: 'https://via.placeholder.com/100x100?text=JS',
      locatarioId: 'current_user',
      locatarioNome: 'Você',
      locatarioFoto: 'https://via.placeholder.com/100x100?text=VC',
      ultimaMensagem: Mensagem(
        id: 'msg1',
        chatId: 'chat1',
        remetenteId: 'user1',
        remetenteNome: 'João Silva',
        conteudo: 'Oi! A furadeira está disponível para amanhã.',
        tipo: TipoMensagem.texto,
        enviadaEm: DateTime.now().subtract(const Duration(minutes: 15)),
        lida: false,
      ),
      mensagensNaoLidas: 1,
      criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Chat(
      id: 'chat2',
      itemId: '2',
      itemNome: 'Bicicleta Mountain Bike',
      itemFoto: 'https://via.placeholder.com/100x100?text=Bike',
      locadorId: 'user2',
      locadorNome: 'Maria Santos',
      locadorFoto: 'https://via.placeholder.com/100x100?text=MS',
      locatarioId: 'current_user',
      locatarioNome: 'Você',
      locatarioFoto: 'https://via.placeholder.com/100x100?text=VC',
      ultimaMensagem: Mensagem(
        id: 'msg2',
        chatId: 'chat2',
        remetenteId: 'current_user',
        remetenteNome: 'Você',
        conteudo: 'Perfeito! Obrigado!',
        tipo: TipoMensagem.texto,
        enviadaEm: DateTime.now().subtract(const Duration(hours: 1)),
        lida: true,
      ),
      mensagensNaoLidas: 0,
      criadoEm: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});

/// Provider para mensagens de um chat específico
final mensagensChatProvider = FutureProvider.family<List<Mensagem>, String>((ref, chatId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  
  // Dados mockados de mensagens
  return [
    Mensagem(
      id: 'msg1',
      chatId: chatId,
      remetenteId: 'user1',
      remetenteNome: 'João Silva',
      conteudo: 'Olá! Vi que você tem interesse na minha furadeira.',
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now().subtract(const Duration(hours: 2)),
      lida: true,
    ),
    Mensagem(
      id: 'msg2',
      chatId: chatId,
      remetenteId: 'current_user',
      remetenteNome: 'Você',
      conteudo: 'Oi! Sim, preciso para um projeto no fim de semana.',
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now().subtract(const Duration(hours: 2, minutes: -5)),
      lida: true,
    ),
    Mensagem(
      id: 'msg3',
      chatId: chatId,
      remetenteId: 'user1',
      remetenteNome: 'João Silva',
      conteudo: 'Perfeito! Ela está em ótimo estado. Quando você precisaria?',
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      lida: true,
    ),
    Mensagem(
      id: 'msg4',
      chatId: chatId,
      remetenteId: 'current_user',
      remetenteNome: 'Você',
      conteudo: 'Seria possível pegar na sexta à tarde e devolver no domingo?',
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      lida: true,
    ),
    Mensagem(
      id: 'msg5',
      chatId: chatId,
      remetenteId: 'user1',
      remetenteNome: 'João Silva',
      conteudo: 'Oi! A furadeira está disponível para amanhã.',
      tipo: TipoMensagem.texto,
      enviadaEm: DateTime.now().subtract(const Duration(minutes: 15)),
      lida: false,
    ),
  ];
});

/// Provider para controlar o envio de mensagens
final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController();
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  ChatController() : super(const AsyncValue.data(null));

  Future<void> enviarMensagem(String chatId, String conteudo) async {
    state = const AsyncValue.loading();
    
    try {
      // Simular envio
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Aqui seria a lógica real de envio
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
