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
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.18; // 18% of screen width
    final iconSize = cardWidth * 0.75; // 75% of card width for icon container

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: iconSize * 0.45),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              nome,
              style: TextStyle(fontSize: screenSize.width * 0.03),
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