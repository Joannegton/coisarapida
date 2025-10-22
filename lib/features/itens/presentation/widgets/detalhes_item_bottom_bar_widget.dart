import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class DetalhesItemBottomBarWidget extends StatelessWidget {
  final Item item;
  final VoidCallback onAlugarPressed;
  final VoidCallback? onComprarPressed;

  const DetalhesItemBottomBarWidget({
    super.key,
    required this.item,
    required this.onAlugarPressed,
    this.onComprarPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela
    
    final bool isAluguel = item.tipo == TipoItem.aluguel;
    final bool isAmbos = item.tipo == TipoItem.ambos; 

    return SafeArea(
      child: Container(
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
        child: isAmbos
            ? Row(
                children: [
                                    // Botão Alugar
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: item.disponivel ? onAlugarPressed : null,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Alugar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ),
                  ),
                  SizedBox(width: padding),
                  // Botão Comprar
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.disponivel
                              ? [
                                  Colors.green.shade700,
                                  Colors.green.shade600,
                                ]
                              : [
                                  Colors.grey.shade400,
                                  Colors.grey.shade400,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: item.disponivel
                            ? [
                                BoxShadow(
                                  color: Colors.green.shade700.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: item.disponivel ? onComprarPressed : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        child: const Text(
                          'Comprar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.disponivel
                        ? [
                            Colors.green.shade700,
                            Colors.green.shade600,
                          ]
                        : [
                            Colors.grey.shade400,
                            Colors.grey.shade400,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: item.disponivel
                      ? [
                          BoxShadow(
                            color: Colors.green.shade700.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: item.disponivel
                      ? (isAluguel ? onAlugarPressed : onComprarPressed)
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  child: Text(
                    isAluguel ? 'Alugar Agora' : 'Comprar Agora',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
