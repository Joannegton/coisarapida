import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';
import '../../domain/entities/item.dart';
import '../../../autenticacao/presentation/widgets/campo_texto_customizado.dart'; // Ajuste o import se necessário

class SessaoPrecos extends StatelessWidget {
  // Controladores
  final TextEditingController precoDiaController;
  final TextEditingController precoHoraController;
  final TextEditingController precoVendaController;
  final TextEditingController caucaoController;

  // Estado e Callbacks
  final TipoItem tipoItem;
  final ValueChanged<TipoItem?> onTipoItemChanged;
  final EstadoItem estadoItem;
  final ValueChanged<EstadoItem?> onEstadoItemChanged;
  final bool aluguelPorHora;
  final ValueChanged<bool> onAluguelPorHoraChanged;
  final bool aprovacaoAutomatica;
  final ValueChanged<bool> onAprovacaoAutomaticaChanged;

  const SessaoPrecos({
    super.key,
    required this.precoDiaController,
    required this.precoHoraController,
    required this.precoVendaController,
    required this.caucaoController,
    required this.tipoItem,
    required this.onTipoItemChanged,
    required this.estadoItem,
    required this.onEstadoItemChanged,
    required this.aluguelPorHora,
    required this.aprovacaoAutomatica,
    required this.onAluguelPorHoraChanged,
    required this.onAprovacaoAutomaticaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAluguel =
        tipoItem == TipoItem.aluguel || tipoItem == TipoItem.ambos;
    final bool isVenda =
        tipoItem == TipoItem.venda || tipoItem == TipoItem.ambos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preços e Configurações',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defina os valores e as condições do seu anúncio',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Seletor de Tipo de Anúncio
          const Text('Tipo de Anúncio',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<TipoItem>(
            segments: const [
              ButtonSegment(value: TipoItem.aluguel, label: Text('Aluguel')),
              ButtonSegment(value: TipoItem.venda, label: Text('Venda')),
              ButtonSegment(value: TipoItem.ambos, label: Text('Ambos')),
            ],
            selected: {tipoItem},
            onSelectionChanged: (selection) =>
                onTipoItemChanged(selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.primary,
              selectedForegroundColor: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Seção de Venda
          if (isVenda) ...[
            Text('Detalhes da Venda', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            CampoTextoCustomizado(
              controller: precoVendaController,
              label: 'Preço de Venda (R\$)',
              hint: '0,00',
              prefixIcon: Icons.sell,
              keyboardType: TextInputType.number,
              validator: isVenda
                  ? Validatorless.required('Preço de venda é obrigatório')
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EstadoItem>(
              value: estadoItem,
              onChanged: onEstadoItemChanged,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado do Item',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star_border_purple500_outlined),
              ),
              items: const [
                DropdownMenuItem(value: EstadoItem.novo, child: Text('Novo')),
                DropdownMenuItem(
                    value: EstadoItem.seminovo, child: Text('Seminovo')),
                DropdownMenuItem(value: EstadoItem.usado, child: Text('Usado')),
                DropdownMenuItem(
                    value: EstadoItem.precisaReparo,
                    child: Text('Com defeito/Precisa de reparo')),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Seção de Aluguel
          if (isAluguel) ...[
            Text('Detalhes do Aluguel', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            CampoTextoCustomizado(
              controller: precoDiaController,
              label: 'Preço por dia (R\$)',
              hint: '0,00',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: isAluguel
                  ? Validatorless.required('Preço por dia é obrigatório')
                  : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Permitir aluguel por hora'),
              value: aluguelPorHora,
              onChanged: onAluguelPorHoraChanged,
            ),
            if (aluguelPorHora) ...[
              const SizedBox(height: 16),
              CampoTextoCustomizado(
                controller: precoHoraController,
                label: 'Preço por hora (R\$)',
                hint: '0,00',
                prefixIcon: Icons.schedule,
                keyboardType: TextInputType.number,
                validator: aluguelPorHora
                    ? Validatorless.required('Preço por hora é obrigatório')
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            CampoTextoCustomizado(
              controller: caucaoController,
              label: 'Caução (R\$) - opcional',
              hint: '0,00',
              prefixIcon: Icons.security,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Aprovação automática de aluguéis'),
              subtitle: Text(aprovacaoAutomatica
                  ? 'Pedidos serão aprovados automaticamente'
                  : 'Você aprovará cada pedido manualmente'),
              value: aprovacaoAutomatica,
              onChanged: onAprovacaoAutomaticaChanged,
            ),
          ],
        ],
      ),
    );
  }
}
