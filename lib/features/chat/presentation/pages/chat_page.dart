import 'package:coisarapida/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/chat_provider.dart';
import '../../domain/entities/mensagem.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/app_routes.dart';

/// Tela de chat individual
class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId; // Adicionado para facilitar a avaliação

  const ChatPage(this.otherUserId, {
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _mensagemController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mensagensState = ref.watch(mensagensChatProvider(widget.chatId));
    final chatDetailsState = ref.watch(chatDetailsProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final chatController = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: chatDetailsState.when(
          data: (chat) {
            if (chat == null) return const Text('Chat');

            final bool souLocador = chat.locadorId == currentUserId;
            final String outroUsuarioNome = souLocador ? chat.locatarioNome : chat.locadorNome;
            final String outroUsuarioFoto = souLocador ? chat.locatarioFoto : chat.locadorFoto;
            final String outroUsuarioId = souLocador ? chat.locatarioId : chat.locadorId;

            return GestureDetector(
              onTap: () => _abrirPerfilUsuario(context, outroUsuarioId),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: outroUsuarioFoto.isNotEmpty ? NetworkImage(outroUsuarioFoto) : null,
                    backgroundColor: outroUsuarioFoto.isNotEmpty ? Colors.transparent : theme.colorScheme.primaryContainer,
                    child: outroUsuarioFoto.isNotEmpty
                        ? null
                        : Text(
                            outroUsuarioNome.isNotEmpty ? outroUsuarioNome[0].toUpperCase() : '?',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outroUsuarioNome,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          chat.itemNome,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Text('Carregando...'),
          error: (err, stack) => const Text('Erro no Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => SnackBarUtils.mostrarInfo(context, 'Ligação em desenvolvimento'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _mostrarOpcoes(context, chatDetailsState.valueOrNull, currentUserId, widget.otherUserId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: mensagensState.when(
              data: (mensagens) {
                // Scroll para o final quando novas mensagens chegam
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) => _buildMensagem(
                    context,
                    theme,
                    mensagens[index], currentUserId,
                ),
              );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Erro ao carregar mensagens: $error'),
              ),
            ), // Adicionada vírgula aqui
          ),
          
          // Campo de entrada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => SnackBarUtils.mostrarInfo(context, 'Anexos em desenvolvimento'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: chatController.isLoading ? null : _enviarMensagem,
                    child: chatController.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensagem(BuildContext context, ThemeData theme, Mensagem mensagem, String? currentUserId) {
    final isMinhaMsg = mensagem.remetenteId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMinhaMsg 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isMinhaMsg) ...[
            GestureDetector(
              onTap: () => _abrirPerfilUsuario(context, mensagem.remetenteId),
              child: CircleAvatar( // Removido 'const'
                radius: 16,
                backgroundImage: null, // Definido como null pois não há URL de imagem do remetente na entidade Mensagem ainda
                // Quando você adicionar 'remetenteFotoUrl' à entidade Mensagem, você pode usar:
                // backgroundImage: mensagem.remetenteFotoUrl != null && mensagem.remetenteFotoUrl!.isNotEmpty
                //    ? NetworkImage(mensagem.remetenteFotoUrl!)
                //    : null,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(mensagem.remetenteNome.isNotEmpty ? mensagem.remetenteNome[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMinhaMsg 
                    ? theme.colorScheme.primary 
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMinhaMsg ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMinhaMsg ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensagem.conteudo,
                    style: TextStyle(
                      color: isMinhaMsg ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarHora(mensagem.enviadaEm),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMinhaMsg 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMinhaMsg) ...[
            const SizedBox(width: 8),
            Icon(
              mensagem.lida ? Icons.done_all : Icons.done,
              size: 16,
              color: mensagem.lida ? Colors.blue : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  void _abrirPerfilUsuario(BuildContext context, String usuarioId) {
    context.push('/perfil-publico/$usuarioId');
  }

  void _enviarMensagem() async {
    final conteudo = _mensagemController.text.trim();
    if (conteudo.isEmpty) return;
    
    _mensagemController.clear();
    
    await ref.read(chatControllerProvider.notifier).enviarMensagem(
      widget.chatId,
      conteudo,
    );
    
    // Scroll para o final
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo( // Usar jumpTo para evitar animação durante o envio rápido
          _scrollController.position.maxScrollExtent,
          // duration: const Duration(milliseconds: 100),
          // curve: Curves.easeOut,
        );
      }
    });
    
    // O StreamProvider já atualiza automaticamente, não precisa de refresh manual aqui.
  }

  void _mostrarOpcoes(BuildContext context, Chat? chat, String? currentUserId, String otherUserIdFromParam) {
    if (chat == null || currentUserId == null) return;

    final bool souLocador = chat.locadorId == currentUserId;
    // Prioriza o otherUserId passado como parâmetro para a página,
    // caso contrário, tenta deduzir do chat.
    final String idDoOutroUsuarioParaAvaliar = otherUserIdFromParam.isNotEmpty
        ? otherUserIdFromParam
        : (souLocador ? chat.locatarioId : chat.locadorId);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                _abrirPerfilUsuario(context, idDoOutroUsuarioParaAvaliar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Informações do item'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.detalhesItem}/${chat.itemId}');
              },
            ),
            // Opção de Avaliar (Provisório)
            ListTile(
              leading: const Icon(Icons.star_outline, color: Colors.amber),
              title: const Text('Avaliar Usuário (Teste)'),
              onTap: () {
                Navigator.pop(context);
                // Para este exemplo, o aluguelId será fixo, mas na prática viria do contexto do chat/item
                // O itemId vem do chat atual.
                const String aluguelIdProvisorio = "aluguel_chat_temp_123";
                context.pushNamed(
                  AppRoutes.avaliacao,
                  queryParameters: {
                    'avaliadoId': idDoOutroUsuarioParaAvaliar,
                    'aluguelId': aluguelIdProvisorio,
                    'itemId': chat.itemId, // Passando o itemId do chat
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Bloquear usuário'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.mostrarInfo(context, 'Bloqueio em desenvolvimento');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Reportar conversa'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.mostrarInfo(context, 'Report em desenvolvimento');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}
