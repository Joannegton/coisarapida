import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/features/chat/domain/entities/chat.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CardChatWidget extends ConsumerWidget {
  const CardChatWidget({super.key, required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usuarioId = ref.watch(idUsuarioAtualProvider);

    if (usuarioId == null) return const SizedBox.shrink();

    final bool souLocador = chat.locadorId == usuarioId;
    final String outroUsuarioNome = souLocador ? chat.locatarioNome : chat.locadorNome;
    final String outroUsuarioFoto = souLocador ? chat.locatarioFoto : chat.locadorFoto;
    final int mensagensNaoLidasParaMim = chat.mensagensNaoLidas[usuarioId] ?? 0;
    final bool temMensagensNaoLidas = mensagensNaoLidasParaMim > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 1,
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: outroUsuarioFoto.isNotEmpty ? NetworkImage(outroUsuarioFoto) : null,
              backgroundColor: outroUsuarioFoto.isNotEmpty ? Colors.transparent : theme.colorScheme.primaryContainer,
              child: outroUsuarioFoto.isNotEmpty
                  ? null
                  : Text(
                    outroUsuarioNome.isNotEmpty ? outroUsuarioNome[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 20, color: theme.colorScheme.onPrimaryContainer),
                  ),
            ),
            if (temMensagensNaoLidas)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
      
                  ),
                  child: Center(
                    child: Text(
                      '$mensagensNaoLidasParaMim',
                      style: TextStyle(color: theme.colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                outroUsuarioNome,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: temMensagensNaoLidas ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatarTempo(chat.ultimaMensagem?.enviadaEm ?? chat.criadoEm),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chat.itemNome,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (chat.ultimaMensagem != null)
              Text(
                chat.ultimaMensagem!.conteudo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: temMensagensNaoLidas ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  fontWeight: temMensagensNaoLidas ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              chat.itemFoto,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        onTap: () => context.push('${AppRoutes.chat}/${chat.id}'),
      ),
    );
  }
}

String _formatarTempo(DateTime tempo) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dataDoTempo = DateTime(tempo.year, tempo.month, tempo.day);

  if (hoje.isAtSameMomentAs(dataDoTempo)) {
    return '${tempo.hour.toString().padLeft(2, '0')}:${tempo.minute.toString().padLeft(2, '0')}';
  }
  final ontem = hoje.subtract(const Duration(days: 1));
  if (ontem.isAtSameMomentAs(dataDoTempo)) {
    return 'Ontem';
  }
  if (agora.difference(tempo).inDays < 7) {
    const diasDaSemana = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
    return diasDaSemana[tempo.weekday] ?? '';
  }
  return '${tempo.day}/${tempo.month}/${tempo.year.toString().substring(2)}';
}