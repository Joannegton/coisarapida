import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Widget _buildChatButton() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Implementar navegação para chat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat será implementado em breve!'),
              ),
            );
          },
          icon: const Icon(Icons.chat),
          label: const Text('Iniciar Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: _buildChatButton(),
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
