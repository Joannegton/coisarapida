import 'package:flutter/material.dart';
import '../../../domain/entities/aluguel.dart';

/// Widget do cabeçalho com status da solicitação
class HeaderSection extends StatelessWidget {
  final Aluguel aluguel;

  const HeaderSection({
    super.key,
    required this.aluguel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo.color,
            statusInfo.color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusInfo.icon,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            statusInfo.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusInfo.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (aluguel.status) {
      case StatusAluguel.solicitado:
        return _StatusInfo(
          icon: Icons.pending_actions,
          title: 'Solicitação Pendente',
          subtitle: 'Aguardando sua aprovação',
          color: Colors.orange,
        );
      case StatusAluguel.aprovado:
        return _StatusInfo(
          icon: Icons.check_circle,
          title: 'Solicitação Aprovada',
          subtitle: 'Aguardando pagamento do locatário',
          color: Colors.green,
        );
      case StatusAluguel.recusado:
        return _StatusInfo(
          icon: Icons.cancel,
          title: 'Solicitação Recusada',
          subtitle: 'Esta solicitação foi recusada',
          color: Colors.red,
        );
      default:
        return _StatusInfo(
          icon: Icons.info,
          title: 'Detalhes da Solicitação',
          subtitle: '',
          color: Colors.blue,
        );
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _StatusInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
