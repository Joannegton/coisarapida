import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class ConfiguracoesRapidas extends StatelessWidget {
  const ConfiguracoesRapidas({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações Rápidas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildItemConfiguracao(
              'Notificações',
              'Gerenciar notificações',
              Icons.notifications,
              () => _configurarNotificacoes(context),
            ),
            
            _buildItemConfiguracao(
              'Privacidade',
              'Configurações de privacidade',
              Icons.privacy_tip,
              () => _configurarPrivacidade(context),
            ),
            
            _buildItemConfiguracao(
              'Suporte',
              'Central de ajuda',
              Icons.help,
              () => _abrirSuporte(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemConfiguracao(
    String titulo,
    String subtitulo,
    IconData icone,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      subtitle: Text(subtitulo),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _configurarNotificacoes(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Configurações de notificação em desenvolvimento');
  }

  void _configurarPrivacidade(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Configurações de privacidade em desenvolvimento');
  }

  void _abrirSuporte(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Suporte em desenvolvimento');
  }
}