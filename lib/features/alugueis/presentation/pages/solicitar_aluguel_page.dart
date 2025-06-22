import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart'; // Importe sua entidade Item
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coisarapida/core/constants/app_routes.dart'; // Para AppRoutes

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

      final dias = _dataFim.difference(_dataInicio).inDays;
      final precoTotal = (dias > 0 ? dias : 1) * widget.item.precoPorDia;

      // Obter dados do locatário (usuário logado)
      final usuarioAsyncValue = ref.read(usuarioAtualProvider);
      final locatario = usuarioAsyncValue.valueOrNull;

      if (locatario == null) {
        if (mounted) {
          SnackBarUtils.mostrarErro(context, 'Usuário não autenticado. Faça login para continuar.');
        }
        return;
      }

      // Gerar um ID único para o aluguel
      final aluguelId = FirebaseFirestore.instance.collection('alugueis_temp').doc().id;

      // Preparar dados para passar para o fluxo de contrato e caução
      final dadosAluguel = {
        'locatarioId': locatario.id,
        'nomeLocatario': locatario.nome,
        'locadorId': widget.item.proprietarioId,
        'nomeLocador': widget.item.proprietarioNome,
        'itemId': widget.item.id,
        'nomeItem': widget.item.nome,
        'itemFotoUrl': widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
        'descricaoItem': widget.item.descricao, // Para o contrato
        'valorAluguel': precoTotal,
        'valorCaucao': widget.item.caucao, // Assumindo que Item tem 'caucao'
        'valorDiaria': widget.item.precoPorDia,
        'dataInicio': _dataInicio.toIso8601String(), // Passar como String para serialização fácil
        'dataFim': _dataFim.toIso8601String(),       // Passar como String
        'observacoesLocatario': _observacoes,
      };

      try {
        // Navegar para a tela de aceite de contrato
        if (mounted) {
          context.push(
            '${AppRoutes.aceiteContrato}/$aluguelId',
            extra: dadosAluguel,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.mostrarErro(context, 'Erro ao iniciar solicitação: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _submeterSolicitacao,
                child: const Text('Continuar para Contrato'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}