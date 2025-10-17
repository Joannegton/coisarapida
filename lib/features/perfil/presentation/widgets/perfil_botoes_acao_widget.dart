import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/shared/widgets/scrolling_text.dart';
import 'package:flutter/material.dart';

class PerfilBotoesAcaoWidget extends StatelessWidget {
  final Usuario usuario;
  final ThemeData theme;
  final VoidCallback onIniciarChat;
  final VoidCallback onVerItensUsuario;

  const PerfilBotoesAcaoWidget({
    super.key,
    required this.usuario,
    required this.theme,
    required this.onIniciarChat,
    required this.onVerItensUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onIniciarChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat),
            label: ScrollingText('Enviar Mensagem'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onVerItensUsuario,
            icon: const Icon(Icons.inventory),
            label: const Text('Ver Itens'),
          ),
        ),
      ],
    );
  }
}