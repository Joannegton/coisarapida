import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/controllers/aluguel_controller.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart' hide aluguelControllerProvider;
import 'package:coisarapida/features/alugueis/presentation/widgets/card_solicitacoes_widget.dart';
import 'package:coisarapida/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SolicitacoesAluguelPage extends ConsumerStatefulWidget {
  const SolicitacoesAluguelPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SolicitacoesAluguelPageState();
}

class _SolicitacoesAluguelPageState extends ConsumerState<SolicitacoesAluguelPage> {

  @override
  Widget build(BuildContext context) {
    final solicitacoesAsync = ref.watch(solicitacoesRecebidasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text('Solicitações Recebidas', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
      body: solicitacoesAsync.when(
        data: (solicitacoes) {
          if (solicitacoes.isEmpty) {
            return const Center(child: Text('Nenhuma solicitação pendente.'));
          }

          final listView = ListView.builder(
            itemCount: solicitacoes.length,
            itemBuilder: (context, index) {
              final aluguel = solicitacoes[index];
              
              return CardSolicitacoesWidget(
                aluguel: aluguel,
                onAprovarSolicitacao: () => _aprovarSolicitacao(context, aluguel),
                onRecusarSolicitacao: () => _recusarSolicitacao(context, ref, aluguel), 
                onChatPressed: () => _abrirChat(),
              );
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

  Future<void> _aprovarSolicitacao(BuildContext context, Aluguel aluguel) async {
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

  //TODO implementar
  Future<void> _abrirChat() async {
    final controller = ref.read(chatControllerProvider.notifier);
  }
  

}