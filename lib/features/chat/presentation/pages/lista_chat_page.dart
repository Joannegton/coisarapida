import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/chat_provider.dart';
import '../../../../core/constants/app_routes.dart';

/// Tela com lista de chats do usuário
class ListaChatsPage extends ConsumerWidget {
  const ListaChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatsState = ref.watch(chatsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
      ),
      body: chatsState.when(
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEstadoVazio(context, theme);
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(chatsProvider);
            },
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) => _buildChatTile(
                context,
                theme,
                chats[index],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar chats: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(chatsProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ThemeData theme, Chat chat) {
    final outroUsuario = chat.locadorNome != 'Você' ? chat.locadorNome : chat.locatarioNome;
    final outroUsuarioFoto = chat.locadorNome != 'Você' ? chat.locadorFoto : chat.locatarioFoto;
    
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(outroUsuarioFoto),
          ),
          if (chat.mensagensNaoLidas > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${chat.mensagensNaoLidas}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              outroUsuario,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: chat.mensagensNaoLidas > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _formatarTempo(chat.ultimaMensagem?.enviadaEm ?? chat.criadoEm),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.itemNome,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (chat.ultimaMensagem != null)
            Text(
              chat.ultimaMensagem!.conteudo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: chat.mensagensNaoLidas > 0 
                    ? Colors.black87 
                    : Colors.grey.shade600,
                fontWeight: chat.mensagensNaoLidas > 0 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          chat.itemFoto,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
      onTap: () => context.push('${AppRoutes.chat}/${chat.id}'),
    );
  }

  Widget _buildEstadoVazio(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma conversa ainda',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quando você entrar em contato com alguém sobre um item, suas conversas aparecerão aqui.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.buscar),
              icon: const Icon(Icons.search),
              label: const Text('Explorar Itens'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarTempo(DateTime tempo) {
    final agora = DateTime.now();
    final diferenca = agora.difference(tempo);
    
    if (diferenca.inMinutes < 1) {
      return 'Agora';
    } else if (diferenca.inHours < 1) {
      return '${diferenca.inMinutes}m';
    } else if (diferenca.inDays < 1) {
      return '${diferenca.inHours}h';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays}d';
    } else {
      return '${tempo.day}/${tempo.month}';
    }
  }
}
