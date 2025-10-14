import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/shared/utils.dart';
import 'package:flutter/material.dart';

class SessaoInformacoesAluguelWidget extends StatelessWidget {
  final Item item;
  final bool alugarPorHora;
  final ValueChanged<bool> onTipoAluguelChanged;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Future<void> Function(BuildContext, bool) selecionarData;
  final double precoTotal;
  final String duracaoTexto;
  final FormFieldSetter<String>? onObservacoesSaved;

  const SessaoInformacoesAluguelWidget({
    super.key,
    required this.item,
    required this.alugarPorHora,
    required this.onTipoAluguelChanged,
    required this.dataInicio,
    required this.dataFim,
    required this.selecionarData,
    required this.precoTotal,
    required this.duracaoTexto,
    this.onObservacoesSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela
    final avatarRadius = screenWidth * 0.08; // 8% da largura

    return 
    Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: avatarRadius,
            backgroundImage: NetworkImage(item.fotos.first),
          ),
          title: Text(
            item.nome,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        SizedBox(height: padding),

        _buildSelectTipoLocacao(theme),

        SizedBox(height: padding),

        Column(
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text('Início do Aluguel', style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(format(dataInicio), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selecionarData(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: Text('Fim do Aluguel', style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(format(dataFim), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selecionarData(context, false),
              style: ListTileStyle.drawer,
            ),
          ],
        ),
      
        SizedBox(height: padding),

        _buildResumoAluguel(context ,theme),

        SizedBox(height: padding * 1.5),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Observações (opcional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          onSaved: onObservacoesSaved,
        ),
      ]
    );
  }

  Widget _buildSelectTipoLocacao(ThemeData theme) {
    if (item.precoPorHora == null) {
      return ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text('Aluguel disponível apenas por dia.', style: TextStyle(color: theme.colorScheme.onSurface)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecione o tipo de aluguel:', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,          
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.calendar_today),
              label: Text('Por Dia (R\$ ${item.precoPorDia.toStringAsFixed(2)})', style: TextStyle(color: theme.colorScheme.onSurface)),
              selected: !alugarPorHora,
              onSelected: (selected) {
                if (selected) {
                  onTipoAluguelChanged(false);
                }
              },
            ),
            ChoiceChip(
              avatar: const Icon(Icons.access_time),
              label: Text('Por Hora (R\$ ${item.precoPorHora!.toStringAsFixed(2)})', style: TextStyle(color: theme.colorScheme.onSurface)),
              selected: alugarPorHora,
              onSelected: (selected) {
                if (selected) {
                  onTipoAluguelChanged(true);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResumoAluguel(BuildContext context, ThemeData theme) {
    final padding = MediaQuery.of(context).size.width * 0.04;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo do Aluguel', style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            )),
            SizedBox(height: padding * 0.75),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Valor Total Estimado:'),
                Text(
                  'R\$ ${precoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Duração total:', style: TextStyle(color: theme.colorScheme.onSurface))),
                Flexible(child: Text(duracaoTexto, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), textAlign: TextAlign.right)),
              ],
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Data de Coleta:', style: TextStyle(color: theme.colorScheme.onSurface))),
                Flexible(child: Text(format(dataInicio), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), textAlign: TextAlign.right)),
              ],
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Data de entrega:', style: TextStyle(color: theme.colorScheme.onSurface))),
                Flexible(child: Text(format(dataFim), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), textAlign: TextAlign.right)),
              ],
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Valor do Caução:', style: TextStyle(color: theme.colorScheme.onSurface))),
                Flexible(child: Text('R\$ ${item.valorCaucao}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), textAlign: TextAlign.right)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String format(DateTime dt) => alugarPorHora
        ? Utils.formatarDataHora(dt)
        : Utils.formatarDataPorExtenso(dt); 
}