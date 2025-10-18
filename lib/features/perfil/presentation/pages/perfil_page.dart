import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../autenticacao/presentation/providers/auth_provider.dart';
import '../../../autenticacao/domain/entities/status_endereco.dart';
import '../providers/perfil_publico_provider.dart'; 
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meuPerfilState = ref.watch(meuPerfilProviderApagar);
    final state = GoRouterState.of(context);
    
    return Scaffold(
      appBar: AppBar(systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.dark ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: theme.brightness == Brightness.dark ? Brightness.dark : Brightness.light,
        ),
        title: const Text('Perfil'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(onPressed: () {
          final fromMenuMais = state.extra is Map && (state.extra as Map)['from'] == 'menu_mais';
          if (fromMenuMais) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        }, icon: const Icon(Icons.arrow_back)),
      ),
      body: meuPerfilState.when(
        data: (usuario) {
          
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Foto e informações básicas
                  _buildCabecalhoPerfil(context, theme, usuario),
                  
                  const SizedBox(height: 10),
                  
                  // Informações pessoais
                  _buildSecaoInformacoes(context, theme, usuario, ref),
                  
                  const SizedBox(height: 10),
                  
                  // Seção de verificações
                  _buildSecaoVerificacoes(context, theme, usuario, ref),
                  
                  const SizedBox(height: 24),
                  
                  // Botão de logout
                  _buildBotaoLogout(context, theme, ref),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar perfil: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(meuPerfilProviderApagar),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalhoPerfil(BuildContext context, ThemeData theme, Usuario usuario) {
    final usuarioVerificado = usuario.cpf != null && usuario.cpf!.isNotEmpty && usuario.emailVerificado &&
      usuario.telefone != null && usuario.telefone!.isNotEmpty && usuario.statusEndereco == StatusEndereco.aprovado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: usuario.fotoUrl != null 
                      ? NetworkImage(usuario.fotoUrl!) 
                      : null,
                  child: usuario.fotoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      iconSize: 20,
                      onPressed: () => _alterarFoto(context),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nome
            Text(
              usuario.nome,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Text(
              usuario.email,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Status de verificação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  usuario.emailVerificado 
                      ? Icons.verified 
                      : Icons.warning,
                  size: 16,
                  color: usuario.emailVerificado 
                      ? Colors.green 
                      : Colors.orange,
                ),
                const SizedBox(width: 10),
                
                Text(
                  usuarioVerificado
                      ? 'Usuario verificado' 
                      : 'Usuario não verificado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: usuarioVerificado 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoInformacoes(BuildContext context, ThemeData theme, Usuario usuario, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Pessoais',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildItemInformacao(
              'Nome',
              usuario.nome,
              Icons.person,
              () => _editarCampoTexto(context, ref, 'Nome', usuario.nome, (novoNome) async {
                await ref.read(authControllerProvider.notifier).atualizarPerfil(nome: novoNome);
              }),
            ),
            
            _buildItemInformacao(
              'Email',
              usuario.email,
              Icons.email,
              null, // Email não editável
            ),
            
            _buildItemInformacao(
              'Telefone',
              usuario.telefone ?? 'Não informado',
              Icons.phone,
              () => _editarCampoTexto(context, ref, 'Telefone', usuario.telefone ?? '', (novoTelefone) async {
                await ref.read(authControllerProvider.notifier).atualizarPerfil(telefone: novoTelefone);
              }, keyboardType: TextInputType.phone),
            ),
            
            _buildItemInformacao(
              'CPF',
              usuario.cpf ?? 'Não informado',
              Icons.badge,
              usuario.cpf != null && usuario.cpf!.isNotEmpty ? null : () => _editarCampoTexto(context, ref, 'CPF', usuario.cpf ?? '', (novoCpf) async {
                await ref.read(authControllerProvider.notifier).atualizarPerfil(cpf: novoCpf);
              }, keyboardType: TextInputType.number),
            ),
            
            _buildItemInformacao(
              'Membro desde',
              _formatarData(usuario.criadoEm),
              Icons.calendar_today,
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInformacao(
    String titulo,
    String valor,
    IconData icone,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onTap,
            ),
        ],
      ),
    );
  }

  Widget _buildSecaoEstatisticas(BuildContext context, ThemeData theme, Usuario usuario) {
    // Determinar se é mais locador ou locatário baseado nas atividades
    final ehLocador = usuario.totalItensAlugados > usuario.totalAlugueis;
    final tituloSecao = ehLocador ? 'Estatísticas como Locador' : 'Estatísticas como Locatário';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloSecao,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (ehLocador) ...[
              // Estatísticas para locador
              Row(
                children: [
                  Expanded(
                    child: _buildEstatistica(
                      'Itens Disponíveis',
                      usuario.totalItensAlugados.toString(),
                      Icons.inventory,
                      theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildEstatistica(
                      'Aluguéis Concluídos',
                      usuario.totalAlugueis.toString(),
                      Icons.check_circle,
                      theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildEstatistica(
                      'Avaliação Média',
                      '${usuario.reputacao.toStringAsFixed(1)} ⭐',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildEstatistica(
                      'Taxa de Sucesso',
                      '95%', // Placeholder - seria calculado baseado em dados reais
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Estatísticas para locatário
              Row(
                children: [
                  Expanded(
                    child: _buildEstatistica(
                      'Aluguéis Realizados',
                      usuario.totalAlugueis.toString(),
                      Icons.handshake,
                      theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildEstatistica(
                      'Itens Alugados',
                      usuario.totalItensAlugados.toString(),
                      Icons.inventory_2,
                      theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildEstatistica(
                      'Avaliação como Locatário',
                      '${usuario.reputacao.toStringAsFixed(1)} ⭐',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildEstatistica(
                      'Economia Total',
                      'R\$ 0', // Placeholder - seria calculado baseado em dados reais
                      Icons.savings,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstatistica(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoConfiguracoes(BuildContext context, ThemeData theme) {
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

  Widget _buildBotaoLogout(BuildContext context, ThemeData theme, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmarLogout(context, ref),
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

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }

  Widget _buildSecaoVerificacoes(BuildContext context, ThemeData theme, Usuario usuario, WidgetRef ref) {
    final telefoneVerificado = usuario.telefone != null && usuario.telefone!.isNotEmpty;
    final enderecoVerificado = usuario.statusEndereco == StatusEndereco.aprovado;
    final cpfVerificado = usuario.cpf != null && usuario.cpf!.isNotEmpty;
    
    // Se tudo verificado, não mostra seção
    if (telefoneVerificado && enderecoVerificado && cpfVerificado) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Segurança',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete suas verificações para desbloquear todas as funcionalidades.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Verificação de telefone
            _buildItemVerificacao(
              context,
              titulo: 'Telefone',
              descricao: telefoneVerificado ? 'Verificado' : 'Não verificado',
              icone: Icons.phone_android,
              verificado: telefoneVerificado,
              onTap: telefoneVerificado ? null : () => context.push(AppRoutes.verificacaoTelefone),
            ),
            
            // Verificação de endereço
            _buildItemVerificacao(
              context,
              titulo: 'Endereço',
              descricao: enderecoVerificado ? 'Verificado' : 'Não verificado',
              icone: Icons.home_outlined,
              verificado: enderecoVerificado,
              onTap: enderecoVerificado ? null : () => context.push(AppRoutes.verificacaoResidencia),
            ),

            // Verificação de CPF
            if (!cpfVerificado) _buildItemVerificacao(
              context,
              titulo: 'CPF',
              descricao: 'Não informado',
              icone: Icons.badge,
              verificado: false,
              onTap: () => _editarCampoTexto(context, ref, 'CPF', usuario.cpf ?? '', (novoCpf) async {
                await ref.read(authControllerProvider.notifier).atualizarPerfil(cpf: novoCpf);
              }, keyboardType: TextInputType.number),
            ),

            _buildItemVerificacao(
              context, 
              titulo: 'E-mail', 
              descricao: usuario.emailVerificado ? 'Verificado' : 'Não verificado',
              icone: Icons.mail_outlined,
              verificado: usuario.emailVerificado,
              onTap: usuario.emailVerificado ? null : () => _abrirGmail(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemVerificacao(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required IconData icone,
    required bool verificado,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              verificado ? Icons.check_circle : icone,
              color: verificado ? Colors.green : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 14,
                      color: verificado ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!verificado && onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _alterarFoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.mostrarInfo(context, 'Câmera em desenvolvimento');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.mostrarInfo(context, 'Galeria em desenvolvimento');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remover foto'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.mostrarInfo(context, 'Remoção em desenvolvimento');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarCampoTexto(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    String valorAtual,
    Future<void> Function(String novoValor) onSalvar, {
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: valorAtual);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Editar $titulo'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(hintText: 'Novo $titulo'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$titulo não pode ser vazio';
                }
                if (titulo == 'Telefone' && !RegExp(r'^\+?[0-9]{10,}$').hasMatch(value)) {
                  return 'Telefone inválido';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(); // Fechar diálogo primeiro
                  try {
                    await onSalvar(controller.text.trim());
                    SnackBarUtils.mostrarSucesso(context, '$titulo atualizado com sucesso!');
                    ref.invalidate(meuPerfilProviderApagar); // Atualiza os dados do perfil na tela
                  } catch (e) {
                    SnackBarUtils.mostrarErro(context, 'Erro ao atualizar $titulo: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        );
      },
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

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
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
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
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

  Future<void> _abrirGmail(BuildContext context) async {
    try {
      final Uri gmailUri = Uri.parse('googlegmail://');
      await launchUrl(gmailUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Gmail'),
          ),
        );
      }
    }
  }
}
