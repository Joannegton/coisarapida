import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tema_provider.dart';
import '../providers/idioma_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/notification_settings_widget.dart';

/// Tela de configurações
class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final temaAtual = ref.watch(temaProvider);
    final idiomaAtual = ref.watch(idiomaProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Aparência
          _buildSecao(
            context,
            theme,
            'Aparência',
            Icons.palette,
            [
              _buildItemTema(context, theme, ref, temaAtual),
              _buildItemIdioma(context, theme, ref, idiomaAtual),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Seção Notificações
          const NotificationSettingsWidget(),
          
          const SizedBox(height: 24),
          
          // Seção Privacidade
          _buildSecao(
            context,
            theme,
            'Privacidade e Segurança',
            Icons.security,
            [
              _buildItemConfiguracao(
                'Alterar Senha',
                'Modificar sua senha de acesso',
                Icons.lock,
                () => _alterarSenha(context),
              ),
              _buildItemConfiguracao(
                'Dados Pessoais',
                'Gerenciar suas informações pessoais',
                Icons.person,
                () => _gerenciarDados(context),
              ),
              _buildItemConfiguracao(
                'Localização',
                'Configurações de localização',
                Icons.location_on,
                () => _configurarLocalizacao(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Seção Suporte
          _buildSecao(
            context,
            theme,
            'Suporte',
            Icons.help,
            [
              _buildItemConfiguracao(
                'Central de Ajuda',
                'Perguntas frequentes e tutoriais',
                Icons.help_center,
                () => _abrirCentralAjuda(context),
              ),
              _buildItemConfiguracao(
                'Fale Conosco',
                'Entre em contato com nosso suporte',
                Icons.chat,
                () => _faleConosco(context),
              ),
              _buildItemConfiguracao(
                'Avaliar App',
                'Avalie nossa experiência na loja',
                Icons.star,
                () => _avaliarApp(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Seção Sobre
          _buildSecao(
            context,
            theme,
            'Sobre',
            Icons.info,
            [
              _buildItemConfiguracao(
                'Versão do App',
                'v1.0.0 (Build 1)',
                Icons.info,
                null,
              ),
              _buildItemConfiguracao(
                'Termos de Uso',
                'Leia nossos termos de serviço',
                Icons.description,
                () => _abrirTermos(context),
              ),
              _buildItemConfiguracao(
                'Política de Privacidade',
                'Como tratamos seus dados',
                Icons.privacy_tip,
                () => _abrirPrivacidade(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Botão de logout
          _buildBotaoLogout(context, theme),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSecao(
    BuildContext context,
    ThemeData theme,
    String titulo,
    IconData icone,
    List<Widget> itens,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...itens,
          ],
        ),
      ),
    );
  }

  Widget _buildItemTema(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    ThemeMode temaAtual,
  ) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Tema'),
      subtitle: Text(_obterNomeTema(temaAtual)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _mostrarSeletorTema(context, ref, temaAtual),
    );
  }

  Widget _buildItemIdioma(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    Locale idiomaAtual,
  ) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Idioma'),
      subtitle: Text(_obterNomeIdioma(idiomaAtual)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _mostrarSeletorIdioma(context, ref, idiomaAtual),
    );
  }

  Widget _buildItemConfiguracao(
    String titulo,
    String subtitulo,
    IconData icone,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      subtitle: Text(subtitulo),
      trailing: onTap != null 
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildBotaoLogout(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _confirmarLogout(context),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Sair da Conta',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _obterNomeTema(ThemeMode tema) {
    switch (tema) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Automático';
    }
  }

  String _obterNomeIdioma(Locale idioma) {
    switch (idioma.languageCode) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      default:
        return 'Português';
    }
  }

  void _mostrarSeletorTema(BuildContext context, WidgetRef ref, ThemeMode atual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              value: ThemeMode.light,
              groupValue: atual,
              onChanged: (valor) {
                if (valor != null) {
                  ref.read(temaProvider.notifier).alterarTema(valor);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro'),
              value: ThemeMode.dark,
              groupValue: atual,
              onChanged: (valor) {
                if (valor != null) {
                  ref.read(temaProvider.notifier).alterarTema(valor);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Automático'),
              value: ThemeMode.system,
              groupValue: atual,
              onChanged: (valor) {
                if (valor != null) {
                  ref.read(temaProvider.notifier).alterarTema(valor);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSeletorIdioma(BuildContext context, WidgetRef ref, Locale atual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: const Text('Português'),
              value: const Locale('pt', 'BR'),
              groupValue: atual,
              onChanged: (valor) {
                if (valor != null) {
                  ref.read(idiomaProvider.notifier).alterarIdioma(valor);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<Locale>(
              title: const Text('English'),
              value: const Locale('en', 'US'),
              groupValue: atual,
              onChanged: (valor) {
                if (valor != null) {
                  ref.read(idiomaProvider.notifier).alterarIdioma(valor);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _alterarSenha(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Alteração de senha em desenvolvimento');
  }

  void _gerenciarDados(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Gerenciamento de dados em desenvolvimento');
  }

  void _configurarLocalizacao(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Configuração de localização em desenvolvimento');
  }

  void _abrirCentralAjuda(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Central de ajuda em desenvolvimento');
  }

  void _faleConosco(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Fale conosco em desenvolvimento');
  }

  void _avaliarApp(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Avaliação em desenvolvimento');
  }

  void _abrirTermos(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Termos de uso em desenvolvimento');
  }

  void _abrirPrivacidade(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Política de privacidade em desenvolvimento');
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SnackBarUtils.mostrarInfo(context, 'Logout em desenvolvimento');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
