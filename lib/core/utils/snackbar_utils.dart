import 'package:flutter/material.dart';

/// Utilitários para exibir SnackBars padronizados
class SnackBarUtils {
  /// Mostrar SnackBar de sucesso
  static void mostrarSucesso(BuildContext context, String mensagem) {
    _mostrarSnackBar(
      context,
      mensagem,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Mostrar SnackBar de erro
  static void mostrarErro(BuildContext context, String mensagem) {
    _mostrarSnackBar(
      context,
      mensagem,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Mostrar SnackBar de aviso
  static void mostrarAviso(BuildContext context, String mensagem) {
    _mostrarSnackBar(
      context,
      mensagem,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Mostrar SnackBar de informação
  static void mostrarInfo(BuildContext context, String mensagem) {
    _mostrarSnackBar(
      context,
      mensagem,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  static void _mostrarSnackBar(
    BuildContext context,
    String mensagem, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
