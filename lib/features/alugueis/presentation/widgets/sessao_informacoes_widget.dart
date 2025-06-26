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

    return 
    Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 30,
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

        const SizedBox(height: 16),

        _buildSelectTipoLocacao(theme),

        const SizedBox(height: 16),

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
      
        const SizedBox(height: 16),

        _buildResumoAluguel(context ,theme),

        const SizedBox(height: 24),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo do Aluguel', style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            )),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Duração total:', style: TextStyle(color: theme.colorScheme.onSurface)),
                Text(duracaoTexto, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Data de Coleta:', style: TextStyle(color: theme.colorScheme.onSurface)),
                Text(format(dataInicio), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Data de entrega:', style: TextStyle(color: theme.colorScheme.onSurface)),
                Text(format(dataFim), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Valor do Caução:', style: TextStyle(color: theme.colorScheme.onSurface)),
                Text('R\$ ${item.valorCaucao}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
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