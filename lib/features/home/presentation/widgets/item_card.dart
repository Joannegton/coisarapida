import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do item
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      image: item.fotos.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.fotos[0]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.fotos.isEmpty
                        ? Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                  // Badge do tipo
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCorTipo(item.tipo),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTextoTipo(item.tipo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Badge do estado
                  if (item.tipo == TipoItem.venda ||
                      item.tipo == TipoItem.ambos)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCorEstado(item.estado),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTextoEstado(item.estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (item.disponivel == false)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Alugado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Informações do item
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPrecoDisplay(item, theme),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Expanded(
                          // TODO: Calculate and display actual distance from user's location
                          child: Text(
                              '${item.localizacao.cidade} - ${item.localizacao.estado}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600)),
                        ),
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(item.avaliacao.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600)),
                      ],
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

  String _getPrecoDisplay(Item item, ThemeData theme) {
    // Prioriza o preço de venda se o item for para venda ou ambos
    if ((item.tipo == TipoItem.venda || item.tipo == TipoItem.ambos) &&
        item.precoVenda != null) {
      return 'R\$ ${item.precoVenda!.toStringAsFixed(2)}';
    }
    // Caso contrário, mostra o preço de aluguel por dia
    if (item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos) {
      return 'R\$ ${item.precoPorDia.toStringAsFixed(2)}/dia';
    }
    // Fallback para o preço de aluguel caso algo não esteja configurado
    // (ex: um item de 'venda' sem precoVenda)
    return 'R\$ ${item.precoPorDia.toStringAsFixed(2)}/dia';
  }

  Color _getCorTipo(TipoItem tipo) {
    switch (tipo) {
      case TipoItem.aluguel:
        return Colors.green;
      case TipoItem.venda:
        return Colors.blue;
      case TipoItem.ambos:
        return Colors.purple;
    }
  }

  String _getTextoTipo(TipoItem tipo) {
    switch (tipo) {
      case TipoItem.aluguel:
        return 'ALUGUEL';
      case TipoItem.venda:
        return 'VENDA';
      case TipoItem.ambos:
        return 'AMBOS';
    }
  }

  Color _getCorEstado(EstadoItem estado) {
    switch (estado) {
      case EstadoItem.novo:
        return Colors.green;
      case EstadoItem.seminovo:
        return Colors.blue;
      case EstadoItem.usado:
        return Colors.orange;
      case EstadoItem.precisaReparo:
        return Colors.red;
    }
  }

  String _getTextoEstado(EstadoItem estado) {
    switch (estado) {
      case EstadoItem.novo:
        return 'NOVO';
      case EstadoItem.seminovo:
        return 'SEMINOVO';
      case EstadoItem.usado:
        return 'USADO';
      case EstadoItem.precisaReparo:
        return 'REPARO';
    }
  }
}
