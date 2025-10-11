import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/alugueis/presentation/widgets/card_solicitacoes_widget.dart';
import 'package:coisarapida/features/alugueis/presentation/helpers/solicitacao_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FiltroSolicitacao {
  todas('Todas'),
  pendentes('Pendentes'),
  aprovadas('Aprovadas'),
  recusadas('Recusadas');

  final String label;
  const FiltroSolicitacao(this.label);
}

class SolicitacoesAluguelPage extends ConsumerStatefulWidget {
  const SolicitacoesAluguelPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SolicitacoesAluguelPageState();
}

class _SolicitacoesAluguelPageState extends ConsumerState<SolicitacoesAluguelPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FiltroSolicitacao _filtroAtual = FiltroSolicitacao.todas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: FiltroSolicitacao.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _filtroAtual = FiltroSolicitacao.values[_tabController.index];
      });
    }
  }

  List<Aluguel> _filtrarSolicitacoes(List<Aluguel> solicitacoes) {
    switch (_filtroAtual) {
      case FiltroSolicitacao.todas:
        return solicitacoes;
      case FiltroSolicitacao.pendentes:
        return solicitacoes.where((s) => s.status == StatusAluguel.solicitado).toList();
      case FiltroSolicitacao.aprovadas:
        return solicitacoes.where((s) => s.status == StatusAluguel.aprovado).toList();
      case FiltroSolicitacao.recusadas:
        return solicitacoes.where((s) => s.status == StatusAluguel.recusado).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitacoesAsync = ref.watch(solicitacoesRecebidasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        title: const Text(
          'Solicitações Recebidas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          indicatorWeight: 3,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          isScrollable: true,
          tabs: FiltroSolicitacao.values.map((filtro) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForFiltro(filtro),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(filtro.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: solicitacoesAsync.when(
        data: (todasSolicitacoes) {
          final solicitacoesFiltradas = _filtrarSolicitacoes(todasSolicitacoes);

          if (todasSolicitacoes.isEmpty) {
            return _buildEmptyState(theme, 'Nenhuma solicitação recebida ainda');
          }

          if (solicitacoesFiltradas.isEmpty) {
            return _buildEmptyState(
              theme,
              'Nenhuma solicitação ${_filtroAtual.label.toLowerCase()}',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com contador
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForFiltro(_filtroAtual),
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${solicitacoesFiltradas.length} ${solicitacoesFiltradas.length == 1 ? 'solicitação' : 'solicitações'}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de solicitações
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: solicitacoesFiltradas.length,
                  itemBuilder: (context, index) {
                    final aluguel = solicitacoesFiltradas[index];
                    
                    return CardSolicitacoesWidget(
                      aluguel: aluguel,
                      onRecusarSolicitacao: () => SolicitacaoHelpers.recusarSolicitacao(
                        context,
                        ref,
                        aluguel,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Carregando solicitações...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
        error: (err, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar solicitações',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(solicitacoesRecebidasProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String mensagem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyIconForFiltro(_filtroAtual),
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            mensagem,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyMessageForFiltro(_filtroAtual),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFiltro(FiltroSolicitacao filtro) {
    switch (filtro) {
      case FiltroSolicitacao.todas:
        return Icons.list_alt;
      case FiltroSolicitacao.pendentes:
        return Icons.pending_actions;
      case FiltroSolicitacao.aprovadas:
        return Icons.check_circle_outline;
      case FiltroSolicitacao.recusadas:
        return Icons.cancel_outlined;
    }
  }

  IconData _getEmptyIconForFiltro(FiltroSolicitacao filtro) {
    switch (filtro) {
      case FiltroSolicitacao.todas:
        return Icons.inbox_outlined;
      case FiltroSolicitacao.pendentes:
        return Icons.pending_outlined;
      case FiltroSolicitacao.aprovadas:
        return Icons.check_circle_outline;
      case FiltroSolicitacao.recusadas:
        return Icons.cancel_outlined;
    }
  }

  String _getEmptyMessageForFiltro(FiltroSolicitacao filtro) {
    switch (filtro) {
      case FiltroSolicitacao.todas:
        return 'Quando alguém solicitar um dos seus itens\nvocê verá as solicitações aqui';
      case FiltroSolicitacao.pendentes:
        return 'Não há solicitações aguardando sua resposta';
      case FiltroSolicitacao.aprovadas:
        return 'Você ainda não aprovou nenhuma solicitação';
      case FiltroSolicitacao.recusadas:
        return 'Você ainda não recusou nenhuma solicitação';
    }
  }
}