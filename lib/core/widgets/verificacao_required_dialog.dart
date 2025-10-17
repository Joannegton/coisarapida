import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

/// Dialog para informar que verificações são necessárias
class VerificacaoRequiredDialog extends StatelessWidget {
  final bool telefoneVerificado;
  final bool enderecoVerificado;
  final String mensagem;

  const VerificacaoRequiredDialog({
    super.key,
    required this.telefoneVerificado,
    required this.enderecoVerificado,
    this.mensagem = 'Para realizar esta ação, você precisa completar as verificações.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Verificação Necessária'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mensagem),
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
    );
  }

  Widget _buildVerificacaoItem(
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
}

// não esta sendo usado?
// mostrarVerificacaoRequiredDialog
// pq?
/// Helper para mostrar o dialog
void mostrarVerificacaoRequiredDialog(
  BuildContext context, {
  required bool telefoneVerificado,
  required bool enderecoVerificado,
  String? mensagem,
}) {
  showDialog(
    context: context,
    builder: (context) => VerificacaoRequiredDialog(
      telefoneVerificado: telefoneVerificado,
      enderecoVerificado: enderecoVerificado,
      mensagem: mensagem ?? 'Para realizar esta ação, você precisa completar as verificações.',
    ),
  );
}

/// Helper para verificar se usuário está totalmente verificado
bool usuarioEstaVerificado({
  required bool telefoneVerificado,
  required bool enderecoVerificado,
}) {
  return telefoneVerificado && enderecoVerificado;
}
