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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nome,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding * 0.5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding * 0.75, vertical: padding * 0.25),
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

          SizedBox(height: padding),

          // Preços
          Wrap(
            spacing: padding * 0.75,
            runSpacing: padding * 0.75,
            children: [
              // Preço de Venda (se aplicável)
              if ((item.tipo == TipoItem.venda ||
                      item.tipo == TipoItem.ambos) &&
                  item.precoVenda != null)
                PrecoCardWidget(
                  titulo: 'Preço de Venda',
                  preco: 'R\$ ${item.precoVenda!.toStringAsFixed(2)}',
                  cor: Colors.green.shade700,
                  isPrincipal: true,
                ),

              // Preço de Aluguel por Dia (se aplicável)
              if (item.tipo == TipoItem.aluguel || item.tipo == TipoItem.ambos)
                PrecoCardWidget(
                  titulo: 'Aluguel por Dia',
                  preco: 'R\$ ${item.precoPorDia.toStringAsFixed(2)}',
                  cor: theme.colorScheme.primary,
                ),

              // Preço de Aluguel por Hora (se aplicável)
              if ((item.tipo == TipoItem.aluguel ||
                      item.tipo == TipoItem.ambos) &&
                  item.precoPorHora != null &&
                  item.precoPorHora! > 0)
                PrecoCardWidget(
                  titulo: 'Aluguel por Hora',
                  preco: 'R\$ ${item.precoPorHora!.toStringAsFixed(2)}',
                  cor: theme.colorScheme.secondary,
                ),
            ],
          ),

          SizedBox(height: padding * 1.25),

          ProprietarioCardWidget(item: item, onChatPressed: onChatPressed),

          SizedBox(height: padding * 1.25),

          Text(
            'Descrição',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding * 0.5),
          Text(item.descricao, style: theme.textTheme.bodyLarge),

          SizedBox(height: padding * 1.25),

          if (item.regrasUso != null && item.regrasUso!.isNotEmpty) ...[
            Text(
              'Regras de Uso',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: padding * 0.5),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: padding * 0.5),
                Expanded(
                    child: Text(item.regrasUso!,
                        style: theme.textTheme.bodyMedium)),
              ]),
            ),
            SizedBox(height: padding * 1.25),
          ],

          // Informações adicionais
          InformacoesAdicionaisWidget(item: item, formatarData: formatarData),
          SizedBox(height: padding * 1.25),

          // Localização
          LocalizacaoCardWidget(item: item),
        ],
      ),
    );
  }
}
