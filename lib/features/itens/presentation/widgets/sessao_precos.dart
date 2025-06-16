import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';
import '../../../autenticacao/presentation/widgets/campo_texto_customizado.dart'; // Ajuste o import se necessário

class SessaoPrecos extends StatelessWidget {
  final TextEditingController precoDiaController;
  final TextEditingController precoHoraController;
  final TextEditingController caucaoController;
  final bool aluguelPorHora;
  final bool aprovacaoAutomatica;
  final ValueChanged<bool> onAluguelPorHoraChanged;
  final ValueChanged<bool> onAprovacaoAutomaticaChanged;

  const SessaoPrecos({
    super.key,
    required this.precoDiaController,
    required this.precoHoraController,
    required this.caucaoController,
    required this.aluguelPorHora,
    required this.aprovacaoAutomatica,
    required this.onAluguelPorHoraChanged,
    required this.onAprovacaoAutomaticaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Defina os valores e como será o aluguel',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Aluguel por hora'),
            subtitle: Text(aluguelPorHora
                ? 'Permitir aluguel por horas'
                : 'Apenas aluguel por dias'),
            value: aluguelPorHora,
            onChanged: onAluguelPorHoraChanged,
          ),
          const SizedBox(height: 16),
          CampoTextoCustomizado(
            controller: precoDiaController,
            label: 'Preço por dia (R\$)',
            hint: '0,00',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: Validatorless.required('Preço por dia é obrigatório'),
          ),
          if (aluguelPorHora) ...[
            const SizedBox(height: 16),
            CampoTextoCustomizado(
              controller: precoHoraController,
              label: 'Preço por hora (R\$)',
              hint: '0,00',
              prefixIcon: Icons.schedule,
              keyboardType: TextInputType.number,
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
            title: const Text('Aprovação automática'),
            subtitle: Text(aprovacaoAutomatica
                ? 'Pedidos serão aprovados automaticamente'
                : 'Você aprovará cada pedido manualmente'),
            value: aprovacaoAutomatica,
            onChanged: onAprovacaoAutomaticaChanged,
          ),
        ],
      ),
    );
  }
}