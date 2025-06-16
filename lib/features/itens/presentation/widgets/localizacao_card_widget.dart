import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class LocalizacaoCardWidget extends StatelessWidget {
  final Item item;

  const LocalizacaoCardWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Localização',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.localizacao.endereco),
            Text('${item.localizacao.bairro}, ${item.localizacao.cidade} - ${item.localizacao.estado}'),
            const SizedBox(height: 8),
            // TODO: Implementar cálculo de distância real
            // Text(
            //   '${item.distancia} km de distância', // Supondo que 'distancia' seja um campo no Item
            //   style: TextStyle(
            //     color: theme.colorScheme.primary,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Mapa em desenvolvimento',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}