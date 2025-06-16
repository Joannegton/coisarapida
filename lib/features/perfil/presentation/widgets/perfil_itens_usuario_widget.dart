import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/perfil/presentation/widgets/item_foto_widget.dart';
import 'package:flutter/material.dart';

class PerfilItensUsuarioWidget extends StatelessWidget {
  final List<Item> itens;
  final Usuario usuario; // Necessário para o "Ver todos" se for implementado aqui
  final ThemeData theme;

  const PerfilItensUsuarioWidget({
    super.key,
    required this.itens,
    required this.usuario,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Itens Anunciados (${itens.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              const Text('Nenhum item anunciado por este usuário.'),
            if (itens.isNotEmpty)
              SizedBox(
                height: 160, // Altura para a lista horizontal de itens
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: itens.length,
                  itemBuilder: (context, index) => ItemFotoWidget(item: itens[index], theme: theme),
                ),
              ),
          ],
        ),
      ),
    );
  }
}