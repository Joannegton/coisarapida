import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';
import 'package:coisarapida/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MensagemWidget extends ConsumerWidget {
  const MensagemWidget({super.key, required this.mensagem});
  final Mensagem mensagem;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usuarioId = ref.watch(idUsuarioAtualProvider);
    final isMinhaMensagem = mensagem.remetenteId == usuarioId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMinhaMensagem ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMinhaMensagem) ...[
            GestureDetector(
              onTap: () => context.push('/perfil-publico/${mensagem.remetenteId}'),
              child: CircleAvatar(
                radius: 16,
                // TODO: Adicionar a foto do remetente na entidade Mensagem
                backgroundImage: null, // Definido como null pois não há URL de imagem do remetente na entidade Mensagem ainda
                // Quando você adicionar 'remetenteFotoUrl' à entidade Mensagem, você pode usar:
                // backgroundImage: mensagem.remetenteFotoUrl != null && mensagem.remetenteFotoUrl!.isNotEmpty
                //    ? NetworkImage(mensagem.remetenteFotoUrl!)
                //    : null,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(mensagem.remetenteNome.isNotEmpty ? mensagem.remetenteNome[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onSecondaryContainer),),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMinhaMensagem ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMinhaMensagem ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMinhaMensagem ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mensagem.conteudo,
                      style: TextStyle(
                        color: isMinhaMensagem ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatarHora(mensagem.enviadaEm),
                        style: TextStyle(
                          fontSize: 11,
                          color: (isMinhaMensagem
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSecondaryContainer)
                              .withAlpha(127),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ),
          if (isMinhaMensagem) ...[
            const SizedBox(width: 8),
            Icon(
              mensagem.lida ? Icons.done_all : Icons.done,
              color: mensagem.lida ? Colors.blue : Colors.grey,
              size: 16,
            ),
          ],
        ],
      ) 
    );
  } 
}

String _formatarHora(DateTime data) {
  return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
}
