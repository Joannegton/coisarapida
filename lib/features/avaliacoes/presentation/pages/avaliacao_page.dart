import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/avaliacao_controller.dart'; // Importar o controller

class AvaliacaoPage extends ConsumerStatefulWidget {
  final String avaliadoId;
  final String aluguelId; // Usado para vincular a avaliação a um aluguel específico
  final String? itemId; // Adicionado itemId

  const AvaliacaoPage({
    super.key,
    required this.avaliadoId,
    required this.aluguelId,
    this.itemId,
  });

  @override
  ConsumerState<AvaliacaoPage> createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends ConsumerState<AvaliacaoPage> {
  final _formKey = GlobalKey<FormState>();
  double _nota = 3.0; // Nota inicial
  String _comentario = '';

  Future<void> _submeterAvaliacao() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final avaliacaoController = ref.read(avaliacaoControllerProvider.notifier);
      try {
        await avaliacaoController.criarAvaliacao(
          avaliadoId: widget.avaliadoId,
          aluguelId: widget.aluguelId,
          itemId: widget.itemId,
          nota: _nota,
          comentario: _comentario.isNotEmpty ? _comentario : null,
        );
        if (!mounted) return;
        SnackBarUtils.mostrarSucesso(context, 'Avaliação enviada com sucesso!');
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        SnackBarUtils.mostrarErro(context, 'Erro ao enviar avaliação: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avaliacaoState = ref.watch(avaliacaoControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Avaliando usuário: ${widget.avaliadoId}'),
              Text('Referente ao aluguel: ${widget.aluguelId}'),
              if (widget.itemId != null) Text('Item relacionado: ${widget.itemId}'),
              const SizedBox(height: 20),
              Text('Sua nota (1-5):', style: theme.textTheme.titleMedium),
              Slider(
                value: _nota,
                min: 1,
                max: 5,
                divisions: 4,
                label: _nota.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _nota = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => _comentario = value ?? '',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: avaliacaoState.isLoading ? null : _submeterAvaliacao,
                child: avaliacaoState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar Avaliação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}