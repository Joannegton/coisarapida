import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';
import 'avaliacao_card_widget.dart';

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
        if (avaliacoes.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 0, right: 12),
              itemCount: avaliacoes.length,
              itemBuilder: (context, index) => AvaliacaoCardWidget(
                avaliacao: avaliacoes[index],
                theme: theme,
              ),
            ),
          ),
      ],
    );
  }
}