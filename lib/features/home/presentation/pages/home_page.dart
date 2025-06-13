import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../autenticacao/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela principal do aplicativo
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar customizada
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                authState.when(
                                  data: (usuario) => Text(
                                    usuario?.nome ?? 'Usuário',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  loading: () => Text(
                                    'Carregando...',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Usuário',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  color: Colors.white,
                                  onPressed: () {
                                    SnackBarUtils.mostrarInfo(
                                      context,
                                      'Notificações em desenvolvimento',
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.help_outline),
                                  color: Colors.white,
                                  onPressed: () {
                                    _mostrarAjuda(context);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'O que você precisa entregar hoje?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ações rápidas
                  _buildAcoesRapidas(context, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Estatísticas
                  _buildEstatisticas(context, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Entregas recentes
                  _buildEntregasRecentes(context, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Dicas e promoções
                  _buildDicasPromocoes(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.novaEntrega),
        icon: const Icon(Icons.add),
        label: const Text('Nova Entrega'),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildAcoesRapidas(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCardAcao(
                context,
                theme,
                'Nova Entrega',
                Icons.add_box,
                theme.colorScheme.primary,
                () => context.push(AppRoutes.novaEntrega),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardAcao(
                context,
                theme,
                'Rastrear',
                Icons.location_on,
                theme.colorScheme.secondary,
                () => _mostrarRastreamento(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardAcao(
                context,
                theme,
                'Histórico',
                Icons.history,
                Colors.orange,
                () => _mostrarHistorico(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardAcao(
                context,
                theme,
                'Suporte',
                Icons.support_agent,
                Colors.purple,
                () => _mostrarSuporte(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardAcao(
    BuildContext context,
    ThemeData theme,
    String titulo,
    IconData icone,
    Color cor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstatisticas(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suas Estatísticas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildEstatistica('Entregas', '12', Icons.local_shipping),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _buildEstatistica('Este Mês', '3', Icons.calendar_month),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _buildEstatistica('Economia', 'R\$ 45', Icons.savings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstatistica(String titulo, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEntregasRecentes(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Entregas Recentes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _mostrarHistorico(context),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildItemEntrega(
          context,
          theme,
          'Documento - Centro',
          'Entregue',
          'Hoje, 14:30',
          Colors.green,
          Icons.check_circle,
        ),
        _buildItemEntrega(
          context,
          theme,
          'Encomenda - Zona Sul',
          'Em trânsito',
          'Ontem, 16:45',
          Colors.blue,
          Icons.local_shipping,
        ),
        _buildItemEntrega(
          context,
          theme,
          'Medicamento - Urgente',
          'Entregue',
          '2 dias atrás',
          Colors.green,
          Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildItemEntrega(
    BuildContext context,
    ThemeData theme,
    String titulo,
    String status,
    String data,
    Color cor,
    IconData icone,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, color: cor, size: 20),
        ),
        title: Text(titulo),
        subtitle: Text(data),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _mostrarDetalhesEntrega(context, titulo),
      ),
    );
  }

  Widget _buildDicasPromocoes(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dicas e Promoções',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dica do Dia',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Agende suas entregas com antecedência para garantir o melhor horário e economizar na taxa de urgência!',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.novaEntrega),
                    child: const Text('Agendar Agora'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarAjuda(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda'),
        content: const Text(
          'Bem-vindo ao Coisa Rápida!\n\n'
          '• Toque em "Nova Entrega" para solicitar uma entrega\n'
          '• Use "Rastrear" para acompanhar suas entregas\n'
          '• Acesse seu histórico para ver entregas anteriores\n'
          '• Entre em contato com o suporte se precisar de ajuda',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _mostrarRastreamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rastrear Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o código da entrega:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Ex: CR123456',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (codigo) {
                Navigator.of(context).pop();
                context.push('${AppRoutes.acompanharEntrega}/$codigo');
              },
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
              context.push('${AppRoutes.acompanharEntrega}/CR123456');
            },
            child: const Text('Rastrear'),
          ),
        ],
      ),
    );
  }

  void _mostrarHistorico(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Histórico em desenvolvimento');
  }

  void _mostrarSuporte(BuildContext context) {
    SnackBarUtils.mostrarInfo(context, 'Suporte em desenvolvimento');
  }

  void _mostrarDetalhesEntrega(BuildContext context, String titulo) {
    SnackBarUtils.mostrarInfo(context, 'Detalhes de: $titulo');
  }
}
