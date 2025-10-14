import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class DetalhesItemBottomBarWidget extends StatelessWidget {
  final Item item;
  final bool isCreatingChat;
  final VoidCallback? onChatPressed;
  final VoidCallback onAlugarPressed;
  final VoidCallback? onComprarPressed;

  const DetalhesItemBottomBarWidget({
    super.key,
    required this.isCreatingChat,
    required this.item,
    this.onChatPressed,
    required this.onAlugarPressed,
    this.onComprarPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela
    
    final bool isAluguel = item.tipo == TipoItem.aluguel;
    final bool isVenda = item.tipo == TipoItem.venda;
    final bool isAmbos = item.tipo == TipoItem.ambos;

    // Define a cor primária para o botão principal
    final Color primaryButtonColor =
        isVenda || isAmbos ? Colors.green.shade700 : theme.colorScheme.primary;

    // Define o texto do botão principal
    String primaryButtonText = 'Alugar Agora';
    if (isVenda) primaryButtonText = 'Comprar Agora';
    if (isAmbos) primaryButtonText = 'Comprar';

    IconData primaryButtonIcon = Icons.calendar_today;
    if (isVenda || isAmbos) primaryButtonIcon = Icons.shopping_cart;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão secundário (Alugar em modo 'Ambos', ou Chat)
            if (isAmbos)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item.disponivel ? onAlugarPressed : null,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Alugar'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: padding * 2),
                  ),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChatPressed,
                  icon: const Icon(Icons.chat),
                  label: isCreatingChat
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Conversar'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: padding * 2),
                  ),
                ),
              ),

            SizedBox(width: padding),

            // Botão principal (Comprar ou Alugar)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: item.disponivel
                    ? (isAluguel ? onAlugarPressed : onComprarPressed)
                    : null,
                icon: Icon(primaryButtonIcon),
                label:
                    Text(item.disponivel ? primaryButtonText : 'Indisponível'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: padding * 2),
                  backgroundColor: primaryButtonColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
