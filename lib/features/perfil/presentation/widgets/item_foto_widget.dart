import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';

class ItemFotoWidget extends StatelessWidget {
  final Item item;
  final ThemeData theme;

  const ItemFotoWidget({
    super.key,
    required this.item,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1, // Imagem quadrada
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: item.fotos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.fotos.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.fotos.isEmpty
                  ? Icon(Icons.image, size: 32, color: Colors.grey.shade400)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.nome, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('R\$ ${item.precoPorDia.toStringAsFixed(2)} / dia'),
        ],
      ),
    );
  }
}