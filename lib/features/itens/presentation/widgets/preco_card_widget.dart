import 'package:flutter/material.dart';

class PrecoCardWidget extends StatelessWidget {
  final String titulo;
  final String preco;
  final Color cor;
  final bool isPrincipal;

  const PrecoCardWidget({
    super.key,
    required this.titulo,
    required this.preco,
    required this.cor,
    this.isPrincipal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrincipal ? cor : cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPrincipal ? null : Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
                color: isPrincipal ? Colors.white : cor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            preco,
            style: TextStyle(
                color: isPrincipal ? Colors.white : cor,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
