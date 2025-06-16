import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final String nome;
  final IconData icone;
  final Color cor;

  const CategoriaCard({
    super.key,
    required this.nome,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              nome,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}