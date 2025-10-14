import 'package:flutter/material.dart';

/// Tela para processamento da caução
/// Este é um widget de UI "burro" que recebe dados e callbacks.
/// A lógica de estado e processamento fica na página pai (`SolicitarAluguelPage`).
class CaucaoConteudoWidget extends StatelessWidget {
  final Map<String, dynamic> dadosAluguel; // Dados passados da AceiteContratoPage
  final String metodoPagamento;
  final ValueChanged<String> onMetodoPagamentoChanged;

  const CaucaoConteudoWidget({
    super.key,
    required this.dadosAluguel,
    required this.metodoPagamento,
    required this.onMetodoPagamentoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extrai dados do aluguel para a UI da caução
    final valorCaucao = (dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
    final nomeItem = dadosAluguel['nomeItem'] as String? ?? 'Item não especificado';
    final valorAluguel = (dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0;
    final dataInicio = DateTime.parse(dadosAluguel['dataInicio'] as String);
    final dataFim = DateTime.parse(dadosAluguel['dataFim'] as String);
    final diffInDays = dataFim.difference(dataInicio).inDays;
    final diasAluguel = diffInDays > 0 ? diffInDays : 1;

    return SingleChildScrollView(
      // O padding já é fornecido pelo PageView
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho explicativo
          _buildCabecalho(theme),
          const SizedBox(height: 24),
          // Detalhes da caução
          _buildDetalhesCaucao(theme, nomeItem, valorAluguel, diasAluguel, valorCaucao),
          const SizedBox(height: 24),
          // Métodos de pagamento
          // _buildMetodosPagamento(theme),
          _buildPagamentoMercadoPago(context, theme),
          const SizedBox(height: 24),
          // Termos e condições
          _buildTermosCondicoes(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCabecalho(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Caução de Segurança',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este valor será bloqueado como garantia e liberado após a devolução do item em perfeitas condições.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhesCaucao(ThemeData theme, String nomeItem, double valorAluguel, int diasAluguel, double valorCaucao) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Caução',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildLinhaDetalhe(theme, 'Item:', nomeItem),
            _buildLinhaDetalhe(theme, 'Valor do aluguel:', 'R\$ ${valorAluguel.toStringAsFixed(2)}'),
            _buildLinhaDetalhe(theme, 'Período:', '$diasAluguel dias'),
            
            const Divider(height: 24),
            
            _buildLinhaDetalhe(
              theme,
              'Valor da caução:',
              'R\$ ${valorCaucao.toStringAsFixed(2)}',
              destaque: true,
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onTertiaryContainer, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este valor será desbloqueado automaticamente após a confirmação da devolução.',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDetalhe(ThemeData theme, String label, String valor, {bool destaque = false}) {
    final textTheme = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: destaque ? FontWeight.bold : null,
            ),
          ),
          Flexible(
            child: Text(
              valor,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: destaque ? theme.colorScheme.primary : null,
                fontSize: destaque ? 16 : 14,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodosPagamento(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Pagamento',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            RadioListTile<String>(
              value: 'cartao',
              groupValue: metodoPagamento,
              onChanged: (value) => onMetodoPagamentoChanged(value!),
              title: const Text('Cartão de Crédito'),
              subtitle: const Text('Bloqueio temporário no cartão'),
              secondary: const Icon(Icons.credit_card),
            ),

            RadioListTile<String>(
              value: 'pix',
              groupValue: metodoPagamento,
              onChanged: (value) => onMetodoPagamentoChanged(value!),
              title: const Text('PIX'),
              subtitle: const Text('Transferência via PIX'),
              secondary: const Icon(Icons.pix),
            ),

            RadioListTile<String>(
              value: 'carteira',
              groupValue: metodoPagamento,
              onChanged: (value) => onMetodoPagamentoChanged(value!),
              title: const Text('Carteira Digital'),
              subtitle: const Text('Saldo da carteira do app'),
              secondary: const Icon(Icons.account_balance_wallet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagamentoMercadoPago(BuildContext context, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo-mercado-pago.png',
              width: screenWidth * 0.5,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  color: Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pagamento Seguro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermosCondicoes(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Condições da Caução',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCondicaoItem('✅ Liberação automática após devolução aprovada', theme),
            const SizedBox(height: 8),
            _buildCondicaoItem('⚠️ Desconto de multas por atraso', theme),
            const SizedBox(height: 8),
            _buildCondicaoItem('🔧 Desconto de custos de reparo em caso de danos', theme),
            const SizedBox(height: 8),
            _buildCondicaoItem('📅 Prazo máximo de 7 dias para liberação', theme),
            const SizedBox(height: 8),
            _buildCondicaoItem('💳 Sem cobrança de juros ou taxas adicionais', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCondicaoItem(String texto, ThemeData theme) {
    return Text(
      texto,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.4,
      ),
    );
  }
}
