import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';
import 'avaliacao_item_widget.dart';

class PerfilAvaliacoesWidget extends StatelessWidget {
  final List<Avaliacao> avaliacoes;
  final ThemeData theme;
  final Function(BuildContext, List<Avaliacao>) onVerTodasPressed;

  const PerfilAvaliacoesWidget({
    super.key,
    required this.avaliacoes,
    required this.theme,
    required this.onVerTodasPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (avaliacoes.isEmpty)
          const Center(child: Text('Nenhuma avaliação recebida ainda.')),
        ...avaliacoes.take(3).map((av) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvaliacaoItemWidget(avaliacao: av, theme: theme),
        )),
        if (avaliacoes.length > 3) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => onVerTodasPressed(context, avaliacoes),
              child: const Text('Ver todas'),
            ),
          ),
        ],
      ],
    );
  }
}