import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';
import 'informacoes_adicionais_widget.dart';
import 'localizacao_card_widget.dart';
import 'preco_card_widget.dart';
import 'proprietario_card_widget.dart';

class DetalhesItemContentWidget extends StatelessWidget {
  final Item item;
  final VoidCallback? onChatPressed;
  final String Function(DateTime) formatarData;

  const DetalhesItemContentWidget({
    super.key,
    required this.item,
    this.onChatPressed,
    required this.formatarData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nome,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.categoria.toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preços
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Preço de Venda (se aplicável)
              if ((item.tipo == TipoItem.venda ||
                      item.tipo == TipoItem.ambos) &&
                  item.precoVenda != null)
                Flexible(
                  child: PrecoCardWidget(
                    titulo: 'Preço de Venda',
                    preco: 'R\$ ${item.precoVenda!.toStringAsFixed(2)}',
                    cor: Colors.green.shade700,
                    isPrincipal: true,
                  ),
                ),

              // Preço de Aluguel por Dia (se aplicável)
              if (item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos)
                Flexible(
                  child: PrecoCardWidget(
                    titulo: 'Aluguel por Dia',
                    preco: 'R\$ ${item.precoPorDia.toStringAsFixed(2)}',
                    cor: theme.colorScheme.primary,
                  ),
                ),

              // Preço de Aluguel por Hora (se aplicável)
              if ((item.tipo == TipoItem.aluguel ||
                      item.tipo == TipoItem.ambos) &&
                  item.precoPorHora != null &&
                  item.precoPorHora! > 0)
                Flexible(
                  child: PrecoCardWidget(
                    titulo: 'Aluguel por Hora',
                    preco: 'R\$ ${item.precoPorHora!.toStringAsFixed(2)}',
                    cor: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          ProprietarioCardWidget(item: item, onChatPressed: onChatPressed),

          const SizedBox(height: 20),

          Text(
            'Descrição',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(item.descricao, style: theme.textTheme.bodyLarge),

          const SizedBox(height: 20),

          if (item.regrasUso != null && item.regrasUso!.isNotEmpty) ...[
            Text(
              'Regras de Uso',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(item.regrasUso!,
                        style: theme.textTheme.bodyMedium)),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Informações adicionais
          InformacoesAdicionaisWidget(item: item, formatarData: formatarData),
          const SizedBox(height: 20),

          // Localização
          LocalizacaoCardWidget(item: item),
        ],
      ),
    );
  }
}
