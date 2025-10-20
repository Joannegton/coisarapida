import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/alugueis/presentation/widgets/card_solicitacoes_widget.dart';
import 'package:coisarapida/features/alugueis/presentation/helpers/solicitacao_helpers.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';

export 'solicitacoes_aluguel_page.dart' show TipoVisualizacao;

enum FiltroSolicitacao {
  todas('Todas'),
  pendentes('Pendentes'),
  aprovadas('Aprovadas'),
  recusadas('Recusadas');

  final String label;
  const FiltroSolicitacao(this.label);
}

enum TipoVisualizacao {
  recebidas('Recebidas'),
  enviadas('Enviadas');

  final String label;
  const TipoVisualizacao(this.label);
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
  TipoVisualizacao _tipoVisualizacao = TipoVisualizacao.recebidas;

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
    // Os providers já trazem os dados corretos (recebidas ou enviadas)
    // Aqui só filtramos por status
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
    final solicitacoesAsync = _tipoVisualizacao == TipoVisualizacao.recebidas
        ? ref.watch(solicitacoesRecebidasProvider)
        : ref.watch(solicitacoesEnviadasProvider);
    final usuarioAsync = ref.watch(usuarioAtualStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        title: Text(
          _tipoVisualizacao == TipoVisualizacao.recebidas
              ? 'Solicitações Recebidas'
              : 'Minhas Solicitações',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botão para alternar entre recebidas e enviadas
          IconButton(
            icon: Icon(
              _tipoVisualizacao == TipoVisualizacao.recebidas
                  ? Icons.swap_horiz
                  : Icons.swap_horiz,
            ),
            tooltip: _tipoVisualizacao == TipoVisualizacao.recebidas
                ? 'Ver minhas solicitações'
                : 'Ver solicitações recebidas',
            onPressed: () {
              setState(() {
                _tipoVisualizacao = _tipoVisualizacao == TipoVisualizacao.recebidas
                    ? TipoVisualizacao.enviadas
                    : TipoVisualizacao.recebidas;
                _tabController.index = 0;
                _filtroAtual = FiltroSolicitacao.todas;
              });
            },
          ),
        ],
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
          final usuario = usuarioAsync.value;
          final solicitacoesFiltradas = _filtrarSolicitacoes(todasSolicitacoes);

          if (solicitacoesFiltradas.isEmpty && _filtroAtual == FiltroSolicitacao.todas) {
            return _buildEmptyState(
              theme,
              _tipoVisualizacao == TipoVisualizacao.recebidas
                  ? 'Nenhuma solicitação recebida'
                  : 'Você ainda não fez nenhuma solicitação',
            );
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
              // Header com contador e tipo de visualização
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
                    final isLocador = usuario?.id == aluguel.locadorId;
                    final isLocatario = usuario?.id == aluguel.locatarioId;
                    
                    return CardSolicitacoesWidget(
                      aluguel: aluguel,
                      isLocador: isLocador,
                      isLocatario: isLocatario,
                      tipoVisualizacao: _tipoVisualizacao,
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
    final isMinhasSolicitacoes = _tipoVisualizacao == TipoVisualizacao.enviadas && _filtroAtual == FiltroSolicitacao.todas;
    
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
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (!isMinhasSolicitacoes) ...[
            Text(
              _getEmptyMessageForFiltro(_filtroAtual),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.pushReplacement(AppRoutes.buscar);
              },
              icon: const Icon(Icons.search),
              label: const Text('Buscar Itens'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore itens disponíveis para alugar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
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
    if (_tipoVisualizacao == TipoVisualizacao.recebidas) {
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
    } else {
      switch (filtro) {
        case FiltroSolicitacao.todas:
          return 'Quando você solicitar alugar algum item\nsuas solicitações aparecerão aqui';
        case FiltroSolicitacao.pendentes:
          return 'Você não tem solicitações aguardando aprovação';
        case FiltroSolicitacao.aprovadas:
          return 'Nenhuma das suas solicitações foi aprovada ainda';
        case FiltroSolicitacao.recusadas:
          return 'Nenhuma das suas solicitações foi recusada';
      }
    }
  }
}