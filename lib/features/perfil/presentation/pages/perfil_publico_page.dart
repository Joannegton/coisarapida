import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:go_router/go_router.dart';
import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';

import '../providers/perfil_publico_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

import '../widgets/perfil_estatisticas_widget.dart';
import '../widgets/perfil_avaliacoes_widget.dart';
import '../widgets/perfil_itens_usuario_widget.dart';
import '../widgets/perfil_botoes_acao_widget.dart';
import '../widgets/avaliacao_item_widget.dart';

/// Tela de perfil público de outro usuário
class PerfilPublicoPage extends ConsumerWidget {
  final String usuarioId;
  
  const PerfilPublicoPage({
    super.key,
    required this.usuarioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final perfilDetalhadoState = ref.watch(perfilPublicoDetalhadoProvider(usuarioId));

    return Scaffold(
      body: perfilDetalhadoState.when(
        data: (perfilDetalhado) {
          final usuario = perfilDetalhado.usuario;
          final String? foto = usuario.fotoUrl;
          return CustomScrollView(
            slivers: [
              // AppBar com foto de capa
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withAlpha((255 *0.8).round()),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 47,
                                  backgroundImage: foto != null && foto.isNotEmpty
                                      ? NetworkImage(foto)
                                      : null,
                                  child: (foto == null || foto.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: theme.colorScheme.primary,
                                        )
                                      : null,
                                ),
                              ),
                              if (usuario.verificado)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Nome
                          Text(
                            usuario.nome,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Localização
                          if (usuario.endereco?.cidade != null && usuario.endereco!.cidade.isNotEmpty)
                            Text(
                              '${usuario.endereco!.cidade}, ${usuario.endereco!.estado}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value, usuario, ref),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'chat',
                        child: Row(
                          children: [
                            Icon(Icons.chat),
                            SizedBox(width: 8),
                            Text('Enviar mensagem'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'compartilhar',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Compartilhar perfil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reportar',
                        child: Row(
                          children: [
                            Icon(Icons.report, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Reportar usuário'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Conteúdo do perfil
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estatísticas
                      PerfilEstatisticasWidget(usuario: usuario, theme: theme),
                      
                      const SizedBox(height: 24),
                      /* TODO: Adicionar campo 'sobre' à entidade Usuario e exibir aqui
                      // Sobre
                      if (usuario['sobre'] != null) ...[
                        _buildSecao(
                          context,
                          theme,
                          'Sobre',
                          Icons.info_outline,
                          [
                            Text(
                              usuario['sobre'],
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      */
                      // Avaliações
                      PerfilAvaliacoesWidget(
                        avaliacoes: perfilDetalhado.avaliacoesRecebidas,
                        theme: theme,
                        onVerTodasPressed: _verTodasAvaliacoes,
                      ),


                      const SizedBox(height: 24),

                      // Itens do usuário
                      PerfilItensUsuarioWidget(
                        itens: perfilDetalhado.itensAnunciados,
                        usuario: usuario,
                        theme: theme,
                      ),

                      const SizedBox(height: 24),

                      // Botões de ação
                      PerfilBotoesAcaoWidget(
                        usuario: usuario,
                        theme: theme,
                        onIniciarChat: () => _iniciarChat(context, usuario, ref),
                        onVerItensUsuario: () => _verItensUsuario(context, usuario),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Perfil')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar perfil: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(perfilPublicoDetalhadoProvider(usuarioId)),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Usuario usuario, WidgetRef ref) {
    switch (action) {
      case 'chat':
        _iniciarChat(context, usuario, ref);
        break;
      case 'compartilhar':
        SnackBarUtils.mostrarInfo(context, 'Compartilhamento em desenvolvimento');
        break;
      case 'reportar':
        _reportarUsuario(context, usuario);
        break;
    }
  }

  void _iniciarChat(BuildContext context, Usuario usuario, WidgetRef ref) {
    // Verificar se usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(
        context,
        ref,
        mensagemCustomizada: 'Para enviar mensagens, você precisa completar as verificações de segurança.',
      );
      return;
    }

    // Simular criação/abertura de chat
    context.push('${AppRoutes.chat}/chat_${usuario.id}'); // Usar o ID real do usuário
  }

  void _verItensUsuario(BuildContext context, Usuario usuario) {
    context.push('${AppRoutes.buscar}?usuarioId=${usuario.id}'); // Passar usuarioId como query param
  }

  void _verTodasAvaliacoes(BuildContext context, List<Avaliacao> avaliacoes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todas as Avaliações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: avaliacoes.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AvaliacaoItemWidget(avaliacao: avaliacoes[index], theme: Theme.of(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportarUsuario(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Usuário'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Por que você está reportando este usuário?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Descreva o motivo...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SnackBarUtils.mostrarSucesso(context, 'Usuário reportado com sucesso');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }
}
