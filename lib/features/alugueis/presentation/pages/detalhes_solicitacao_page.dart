import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../autenticacao/presentation/providers/auth_provider.dart';
import '../../domain/entities/aluguel.dart';
import '../helpers/solicitacao_helpers.dart';
import '../widgets/detalhes_solicitacao/header_section.dart';
import '../widgets/detalhes_solicitacao/item_info_section.dart';
import '../widgets/detalhes_solicitacao/locatario_info_section.dart';
import '../widgets/detalhes_solicitacao/periodo_info_section.dart';
import '../widgets/detalhes_solicitacao/valor_info_section.dart';
import '../widgets/detalhes_solicitacao/observacoes_section.dart';
import '../widgets/detalhes_solicitacao/action_buttons_section.dart';

/// Página de detalhes de uma solicitação de aluguel
class DetalhesSolicitacaoPage extends ConsumerStatefulWidget {
  final Aluguel aluguel;

  const DetalhesSolicitacaoPage({
    super.key,
    required this.aluguel,
  });

  @override
  ConsumerState<DetalhesSolicitacaoPage> createState() =>
      _DetalhesSolicitacaoPageState();
}

class _DetalhesSolicitacaoPageState
    extends ConsumerState<DetalhesSolicitacaoPage> {
  bool _isLoading = false;

  Future<void> _handleAprovarSolicitacao() async {
    setState(() => _isLoading = true);
    try {
      await SolicitacaoHelpers.aprovarSolicitacao(
        context,
        ref,
        widget.aluguel,
        fecharPaginaAposAprovar: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRecusarSolicitacao() async {
    setState(() => _isLoading = true);
    try {
      await SolicitacaoHelpers.recusarSolicitacao(
        context,
        ref,
        widget.aluguel,
        fecharPaginaAposRecusar: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusButton(ThemeData theme, bool isLocador, bool isLocatario) {
    final dadosParaStatus = {
      'itemId': widget.aluguel.itemId,
      'nomeItem': widget.aluguel.itemNome,
      'valorAluguel': widget.aluguel.precoTotal.toString(),
      'valorCaucao': widget.aluguel.caucao.valor.toString(),
      'dataLimiteDevolucao': widget.aluguel.dataFim.toIso8601String(),
      'locadorId': widget.aluguel.locadorId,
      'nomeLocador': widget.aluguel.locadorNome,
      'valorDiaria': (widget.aluguel.precoTotal / widget.aluguel.dataFim.difference(widget.aluguel.dataInicio).inDays).toString(),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão para ver status do aluguel
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/status-aluguel/${widget.aluguel.id}', extra: dadosParaStatus);
                },
                icon: const Icon(Icons.timeline, size: 24),
                label: Text(
                  isLocador ? 'Gerenciar Aluguel' : 'Ver Status do Aluguel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botão de chat (se for locatário)
            if (isLocatario)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar navegação para chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat será implementado em breve!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Conversar com Locador'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuarioAsync = ref.watch(usuarioAtualStreamProvider);
    final usuario = usuarioAsync.value;
    final isLocador = usuario?.id == widget.aluguel.locadorId;
    final isLocatario = usuario?.id == widget.aluguel.locatarioId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Solicitação'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header com status
                HeaderSection(aluguel: widget.aluguel),

                const SizedBox(height: 16),

                // Informações do item
                ItemInfoSection(aluguel: widget.aluguel),

                const SizedBox(height: 16),

                // Informações do locatário
                LocatarioInfoSection(aluguel: widget.aluguel),

                const SizedBox(height: 16),

                // Informações do período
                PeriodoInfoSection(aluguel: widget.aluguel),

                const SizedBox(height: 16),

                // Informações de valor
                ValorInfoSection(aluguel: widget.aluguel),

                const SizedBox(height: 16),

                // Observações do locatário
                if (widget.aluguel.observacoesLocatario != null &&
                    widget.aluguel.observacoesLocatario!.isNotEmpty)
                  ObservacoesSection(
                    observacoes: widget.aluguel.observacoesLocatario!,
                  ),

                const SizedBox(height: 100), // Espaço para os botões fixos
              ],
            ),
          ),

          // Botões de ação fixos na parte inferior
          if (widget.aluguel.status == StatusAluguel.solicitado)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ActionButtonsSection(
                isLoading: _isLoading,
                onAprovar: _handleAprovarSolicitacao,
                onRecusar: _handleRecusarSolicitacao,
              ),
            )
          else if (widget.aluguel.status == StatusAluguel.aprovado)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStatusButton(theme, isLocador, isLocatario),
            ),
        ],
      ),
    );
  }
}

/// Diálogo para inserir motivo de recusa
class _MotivoRecusaDialog extends StatefulWidget {
  @override
  State<_MotivoRecusaDialog> createState() => _MotivoRecusaDialogState();
}

class _MotivoRecusaDialogState extends State<_MotivoRecusaDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Motivo da Recusa'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Digite o motivo da recusa...',
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
        maxLength: 500,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Recusar'),
        ),
      ],
    );
  }
}
