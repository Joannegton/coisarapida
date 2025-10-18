import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final double? distancia;

  const ItemCard({super.key, required this.item, this.distancia});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.detalhesItem}/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do item
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      image: item.fotos.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.fotos[0]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.fotos.isEmpty
                        ? Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  // Badge do tipo
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCorTipo(item.tipo).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getTextoTipo(item.tipo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  // Badge do estado (apenas para venda)
                  if (item.tipo == TipoItem.venda || item.tipo == TipoItem.ambos)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCorEstado(item.estado).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getTextoEstado(item.estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Badge de indisponível
                  if (item.disponivel == false)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'INDISPONÍVEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Informações do item
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.nome,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getPrecoDisplay(item, theme),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          distancia != null ? '${distancia!.toStringAsFixed(1)} km' : item.localizacao.bairro,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 13,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.avaliacao.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
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
