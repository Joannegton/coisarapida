import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/alugueis/presentation/controllers/aluguel_controller.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart'; // Importe sua entidade Item
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SolicitarAluguelPage extends ConsumerStatefulWidget {
  final Item item; // O item para o qual o aluguel está sendo solicitado

  const SolicitarAluguelPage({super.key, required this.item});

  @override
  ConsumerState<SolicitarAluguelPage> createState() => _SolicitarAluguelPageState();
}

class _SolicitarAluguelPageState extends ConsumerState<SolicitarAluguelPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 1));
  String _observacoes = '';

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Não permitir datas passadas
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dataSelecionada != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = dataSelecionada;
          if (_dataFim.isBefore(_dataInicio)) {
            _dataFim = _dataInicio.add(const Duration(days: 1));
          }
        } else {
          _dataFim = dataSelecionada;
          if (_dataFim.isBefore(_dataInicio)) {
            _dataInicio = _dataFim.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  void _submeterSolicitacao() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Simples cálculo de preço total (exemplo)
      final dias = _dataFim.difference(_dataInicio).inDays;
      final precoTotal = (dias > 0 ? dias : 1) * widget.item.precoPorDia;

      final controller = ref.read(aluguelControllerProvider.notifier);
      try {
        final aluguelId = await controller.solicitarAluguel(
          item: widget.item,
          dataInicio: _dataInicio,
          dataFim: _dataFim,
          precoTotal: precoTotal,
          observacoesLocatario: _observacoes,
        );
        if (mounted && aluguelId != null) {
          SnackBarUtils.mostrarSucesso(context, 'Solicitação de aluguel enviada!');
          // Navegar para meus aluguéis ou para o chat com o locador
          context.pop(); // Voltar para a tela anterior (detalhes do item, por exemplo)
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.mostrarErro(context, 'Erro ao solicitar aluguel: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(aluguelControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Solicitar Aluguel de ${widget.item.nome}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Item: ${widget.item.nome}'),
              Text('Preço por dia: R\$ ${widget.item.precoPorDia.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              ListTile(title: Text('Data de Início: ${_dataInicio.toLocal().toString().split(' ')[0]}'), trailing: const Icon(Icons.calendar_today), onTap: () => _selecionarData(context, true)),
              ListTile(title: Text('Data de Fim: ${_dataFim.toLocal().toString().split(' ')[0]}'), trailing: const Icon(Icons.calendar_today), onTap: () => _selecionarData(context, false)),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Observações (opcional)', border: OutlineInputBorder()),
                maxLines: 3,
                onSaved: (value) => _observacoes = value ?? '',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _submeterSolicitacao,
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar Solicitação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}