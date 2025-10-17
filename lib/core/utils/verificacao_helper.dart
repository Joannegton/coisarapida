import 'package:coisarapida/features/autenticacao/domain/entities/status_endereco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/autenticacao/presentation/providers/auth_provider.dart';
import '../constants/app_routes.dart';

/// Helper para verificar se o usuário está 100% verificado
class VerificacaoHelper {
  /// Verifica se o usuário está completamente verificado
  /// Retorna true apenas se telefone E endereço estiverem verificados
  static bool usuarioVerificado(WidgetRef ref) {
    final authState = ref.watch(usuarioAtualStreamProvider);
    if (!authState.hasValue || authState.value == null) return false;
    
    final possuiTelefone = authState.value != null ? true : false;

    //TODO adicionar verificacao de email tbm
    final usuario = authState.value!;
    return possuiTelefone && usuario.statusEndereco == StatusEndereco.aprovado;
  }

  /// Mostra dialog informando sobre verificações necessárias
  static void mostrarDialogVerificacao(BuildContext context, WidgetRef ref,
      {String? mensagemCustomizada}) {
    final authState = ref.watch(usuarioAtualStreamProvider);
    if (!authState.hasValue || authState.value == null) return;

    final usuario = authState.value!;
    final telefoneVerificado = usuario.telefone != null && usuario.telefone!.isNotEmpty;
    final enderecoVerificado = usuario.statusEndereco == StatusEndereco.aprovado;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Verificação Necessária'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensagemCustomizada ??
                'Para realizar esta ação, você precisa completar as verificações de segurança.'),
            const SizedBox(height: 16),
            const Text(
              'Verificações pendentes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!telefoneVerificado)
              _buildVerificacaoItem(
                context,
                icon: Icons.phone_android,
                titulo: 'Verificar Telefone',
                descricao: 'Confirme seu número de celular',
                concluido: false,
              ),
            if (!enderecoVerificado)
              _buildVerificacaoItem(
                context,
                icon: Icons.home_outlined,
                titulo: 'Verificar Endereço',
                descricao: 'Confirme seu endereço residencial',
                concluido: false,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Redirecionar para a próxima verificação pendente
              if (!telefoneVerificado) {
                context.push(AppRoutes.verificacaoTelefone);
              } else if (!enderecoVerificado) {
                context.push(AppRoutes.verificacaoResidencia);
              }
            },
            child: const Text('Verificar Agora'),
          ),
        ],
      ),
    );
  }

  static Widget _buildVerificacaoItem(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String descricao,
    required bool concluido,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            concluido ? Icons.check_circle : icon,
            color: concluido ? Colors.green : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: concluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  descricao,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra um banner informativo sobre verificações pendentes
  static Widget? bannerVerificacao(WidgetRef ref, BuildContext context) {
    final authState = ref.watch(usuarioAtualStreamProvider);
    if (!authState.hasValue || authState.value == null) return null;

    final usuario = authState.value!;
    final enderecoVerificado = usuario.statusEndereco == StatusEndereco.aprovado;
    final telefoneVerificado = usuario.telefone != null && usuario.telefone!.isNotEmpty;

    // Se está tudo verificado, não mostra banner
    if (enderecoVerificado && telefoneVerificado) return null;

    // Mensagem sobre verificações pendentes
    String mensagem = 'Complete as verificações para desbloquear todas as funcionalidades';
    IconData icone = Icons.warning_amber_rounded;
    Color cor = Colors.orange;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensagem,
                  style: TextStyle(
                    fontSize: 14,
                    color: cor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toque para verificar agora',
                  style: TextStyle(
                    fontSize: 12,
                    color: cor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: cor, size: 16),
        ],
      ),
    );
  }
}

