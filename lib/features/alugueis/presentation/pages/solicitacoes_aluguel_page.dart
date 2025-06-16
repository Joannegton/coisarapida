import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/controllers/aluguel_controller.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart' hide aluguelControllerProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SolicitacoesAluguelPage extends ConsumerWidget {
  const SolicitacoesAluguelPage({super.key});

  Future<void> _aprovarSolicitacao(BuildContext context, WidgetRef ref, Aluguel aluguel) async {
    final controller = ref.read(aluguelControllerProvider.notifier);
    try {
      await controller.atualizarStatusAluguel(aluguel.id, StatusAluguel.aprovado);
      if (context.mounted) {
        SnackBarUtils.mostrarSucesso(context, 'Solicitação aprovada!');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao aprovar: ${e.toString()}');
      }
    }
  }

  Future<void> _recusarSolicitacao(BuildContext context, WidgetRef ref, Aluguel aluguel) async {
    // Opcional: Adicionar um dialog para inserir o motivo da recusa
    String? motivoRecusa;
    final motivoController = TextEditingController();

    final bool confirmarRecusa = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Recusar Solicitação'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tem certeza que deseja recusar esta solicitação?'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: motivoController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo da recusa (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                ElevatedButton(
                  child: const Text('Confirmar Recusa'),
                  onPressed: () {
                    motivoRecusa = motivoController.text.trim();
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmarRecusa) {
      final controller = ref.read(aluguelControllerProvider.notifier);
      try {
        await controller.atualizarStatusAluguel(aluguel.id, StatusAluguel.recusado, motivo: motivoRecusa);
        if (context.mounted) {
          SnackBarUtils.mostrarInfo(context, 'Solicitação recusada.');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.mostrarErro(context, 'Erro ao recusar: ${e.toString()}');
        }
      }
    }
    motivoController.dispose();
  }

  String _formatarDataSimples(DateTime data) {
    // Formato D/M/AAAA
    return "${data.day}/${data.month}/${data.year}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitacoesAsync = ref.watch(solicitacoesRecebidasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações Recebidas')),
      body: solicitacoesAsync.when(
        data: (solicitacoes) {
          debugPrint('[SolicitacoesAluguelPage] WHEN: Data recebida com ${solicitacoes.length} solicitações.');
          if (solicitacoes.isEmpty) {
            return const Center(child: Text('Nenhuma solicitação pendente.'));
          }
          final listView = ListView.builder(
            itemCount: solicitacoes.length,
            itemBuilder: (context, index) {
              final aluguel = solicitacoes[index];
              final periodoFormatado = '${_formatarDataSimples(aluguel.dataInicio)} a ${_formatarDataSimples(aluguel.dataFim)}';
              
              final cardWidget = Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aluguel.itemNome, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Solicitante: ${aluguel.locatarioNome}'),
                      Text('Período: $periodoFormatado'),
                      Text('Valor Total: R\$ ${aluguel.precoTotal.toStringAsFixed(2)}'),
                      if (aluguel.observacoesLocatario != null && aluguel.observacoesLocatario!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Obs: ${aluguel.observacoesLocatario}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min, // Adicionado para restringir a largura da Row
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => _recusarSolicitacao(context, ref, aluguel), child: const Text('Recusar', style: TextStyle(color: Colors.red))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(88, 36), // Garante um tamanho mínimo finito
                            ),
                            onPressed: () => _aprovarSolicitacao(context, ref, aluguel), 
                            child: const Text('Aprovar')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              return cardWidget;
            },
          );
          return listView;
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, stack) {
          return Center(child: Text('Erro ao carregar solicitações: $err'));
        },
      ),
    );
  }
}