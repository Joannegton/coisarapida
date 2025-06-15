import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/perfil_publico_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

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
    final perfilState = ref.watch(perfilPublicoProvider(usuarioId));
    
    return Scaffold(
      body: perfilState.when(
        data: (usuario) => CustomScrollView(
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
                        theme.colorScheme.primary.withOpacity(0.8),
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
                                backgroundImage: usuario['fotoUrl'] != null 
                                    ? NetworkImage(usuario['fotoUrl']!) 
                                    : null,
                                child: usuario['fotoUrl'] == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              ),
                            ),
                            if (usuario['verificado'] == true)
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
                          usuario['nome'] ?? 'Usuário',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Localização
                        if (usuario['cidade'] != null)
                          Text(
                            usuario['cidade'],
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
                  onSelected: (value) => _handleMenuAction(context, value, usuario),
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
                    _buildEstatisticas(context, theme, usuario),
                    
                    const SizedBox(height: 24),
                    
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
                    
                    // Avaliações
                    _buildAvaliacoes(context, theme, usuario),
                    
                    const SizedBox(height: 24),
                    
                    // Itens do usuário
                    _buildItensUsuario(context, theme, usuario),
                    
                    const SizedBox(height: 24),
                    
                    // Botões de ação
                    _buildBotoesAcao(context, theme, usuario),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  onPressed: () => ref.refresh(perfilPublicoProvider(usuarioId)),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstatisticas(BuildContext context, ThemeData theme, Map<String, dynamic> usuario) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildEstatistica(
                'Itens',
                '${usuario['totalItens'] ?? 0}',
                Icons.inventory,
                theme.colorScheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildEstatistica(
                'Aluguéis',
                '${usuario['totalAlugueis'] ?? 0}',
                Icons.handshake,
                theme.colorScheme.secondary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildEstatistica(
                'Avaliação',
                '${usuario['reputacao']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatistica(String titulo, String valor, IconData icone, Color cor) {
    return Column(
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
    );
  }

  Widget _buildSecao(
    BuildContext context,
    ThemeData theme,
    String titulo,
    IconData icone,
    List<Widget> children,
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAvaliacoes(BuildContext context, ThemeData theme, Map<String, dynamic> usuario) {
    final avaliacoes = usuario['avaliacoes'] as List<Map<String, dynamic>>? ?? [];
    
    return _buildSecao(
      context,
      theme,
      'Avaliações (${avaliacoes.length})',
      Icons.rate_review,
      [
        if (avaliacoes.isEmpty)
          const Text('Nenhuma avaliação ainda')
        else
          ...avaliacoes.take(3).map((avaliacao) => _buildAvaliacaoItem(theme, avaliacao)),
        if (avaliacoes.length > 3)
          TextButton(
            onPressed: () => _verTodasAvaliacoes(context, avaliacoes),
            child: const Text('Ver todas as avaliações'),
          ),
      ],
    );
  }

  Widget _buildAvaliacaoItem(ThemeData theme, Map<String, dynamic> avaliacao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avaliacao['autorFoto'] != null 
                ? NetworkImage(avaliacao['autorFoto']) 
                : null,
            child: avaliacao['autorFoto'] == null 
                ? const Icon(Icons.person, size: 20) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      avaliacao['autorNome'] ?? 'Usuário',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        Icons.star,
                        size: 14,
                        color: index < (avaliacao['nota'] ?? 0) 
                            ? Colors.orange 
                            : Colors.grey.shade300,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  avaliacao['comentario'] ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarData(DateTime.parse(avaliacao['data'] ?? DateTime.now().toIso8601String())),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItensUsuario(BuildContext context, ThemeData theme, Map<String, dynamic> usuario) {
    final itens = usuario['itens'] as List<Map<String, dynamic>>? ?? [];
    
    return _buildSecao(
      context,
      theme,
      'Itens Disponíveis (${itens.length})',
      Icons.inventory,
      [
        if (itens.isEmpty)
          const Text('Nenhum item anunciado')
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: itens.length,
              itemBuilder: (context, index) => _buildItemCard(context, theme, itens[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, ThemeData theme, Map<String, dynamic> item) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('${AppRoutes.detalhesItem}/${item['id']}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: item['fotos'] != null && item['fotos'].isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item['fotos'][0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item['fotos'] == null || item['fotos'].isEmpty
                      ? Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nome'] ?? 'Item',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${item['precoPorDia']?.toStringAsFixed(2) ?? '0,00'}/dia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotoesAcao(BuildContext context, ThemeData theme, Map<String, dynamic> usuario) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _iniciarChat(context, usuario),
            icon: const Icon(Icons.chat),
            label: const Text('Enviar Mensagem'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _verItensUsuario(context, usuario),
            icon: const Icon(Icons.inventory),
            label: const Text('Ver Itens'),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action, Map<String, dynamic> usuario) {
    switch (action) {
      case 'chat':
        _iniciarChat(context, usuario);
        break;
      case 'compartilhar':
        SnackBarUtils.mostrarInfo(context, 'Compartilhamento em desenvolvimento');
        break;
      case 'reportar':
        _reportarUsuario(context, usuario);
        break;
    }
  }

  void _iniciarChat(BuildContext context, Map<String, dynamic> usuario) {
    // Simular criação/abertura de chat
    context.push('${AppRoutes.chat}/chat_${usuario['id']}');
  }

  void _verItensUsuario(BuildContext context, Map<String, dynamic> usuario) {
    context.push('${AppRoutes.buscar}?usuario=${usuario['id']}');
  }

  void _verTodasAvaliacoes(BuildContext context, List<Map<String, dynamic>> avaliacoes) {
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
                    child: _buildAvaliacaoItem(Theme.of(context), avaliacoes[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportarUsuario(BuildContext context, Map<String, dynamic> usuario) {
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

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }
}
