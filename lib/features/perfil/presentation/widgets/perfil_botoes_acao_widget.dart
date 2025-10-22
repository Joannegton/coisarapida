import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';

class PerfilBotoesAcaoWidget extends StatelessWidget {
  final Usuario usuario;
  final ThemeData theme;
  final bool isProprioUsuario;
  final VoidCallback onIniciarChat;
  final VoidCallback onVerItensUsuario;

  const PerfilBotoesAcaoWidget({
    super.key,
    required this.usuario,
    required this.theme,
    required this.isProprioUsuario,
    required this.onIniciarChat,
    required this.onVerItensUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProprioUsuario ? null : onIniciarChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: isProprioUsuario 
                  ? Colors.grey.shade300 
                  : theme.colorScheme.primary,
              foregroundColor: isProprioUsuario 
                  ? Colors.grey.shade600 
                  : Colors.white,
            ),
            icon: const Icon(Icons.chat),
            label: Text(isProprioUsuario ? 'Este é seu perfil' : 'Enviar Mensagem'),
          ),
        ),
        // const SizedBox(width: 12),
        // Expanded(
        //   child: OutlinedButton.icon(
        //     onPressed: onVerItensUsuario,
        //     icon: const Icon(Icons.inventory),
        //     label: const Text('Ver Itens'),
        //   ),
        // ),
      ],
    );
  }
}