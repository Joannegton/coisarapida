import 'package:coisarapida/core/providers/notification_provider.dart';
import 'package:coisarapida/features/configuracoes/presentation/providers/tema_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfiguracoesRapidas extends ConsumerWidget {
  const ConfiguracoesRapidas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final temaAtual = ref.watch(temaProvider);
    final notificationService = ref.watch(notificationServiceProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações Rápidas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Switch de Notificações
            FutureBuilder<bool>(
              future: notificationService.hasPermission(),
              builder: (context, snapshot) {
                final hasPermission = snapshot.data ?? false;
                return _buildItemSwitch(
                  context,
                  ref,
                  'Notificações',
                  'Ativar notificações do app',
                  Icons.notifications_outlined,
                  hasPermission,
                  (value) async {
                    if (value) {
                      await notificationService.requestPermission();
                      final granted = await notificationService.hasPermission();
                      if (!granted && context.mounted) {
                        _mostrarDialogoPermissao(context);
                      }
                    } else {
                      if (context.mounted) {
                        _mostrarDialogoDesativar(context);
                      }
                    }
                  },
                );
              },
            ),
            
            const Divider(height: 1),
            
            // Switch de Tema
            _buildItemSwitch(
              context,
              ref,
              temaAtual == ThemeMode.dark ? 'Tema Escuro' : 'Tema Claro',
              temaAtual == ThemeMode.dark ? 'Modo escuro ativado' : 'Modo claro ativado',
              temaAtual == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              temaAtual == ThemeMode.dark,
              (value) {
                ref.read(temaProvider.notifier).alterarTema(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSwitch(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    String subtitulo,
    IconData icone,
    bool valor,
    Function(bool) onChanged,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SwitchListTile(
      secondary: Icon(icone, size: screenWidth * 0.06),
      title: Text(titulo),
      subtitle: Text(subtitulo),
      value: valor,
      onChanged: onChanged,
    );
  }

  void _mostrarDialogoPermissao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Negada'),
        content: const Text(
          'Para receber notificações, você precisa ativar a permissão nas configurações do seu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoDesativar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Notificações'),
        content: const Text(
          'Para desativar as notificações, acesse as configurações do seu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }
}