import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/aceite_contrato_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/caucao_page.dart' show CaucaoConteudoWidget;
import 'package:coisarapida/features/alugueis/presentation/widgets/sessao_informacoes_widget.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/seguranca/domain/entities/contrato.dart';
import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart'; // Import adicionado
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/aluguel.dart';
import '../providers/aluguel_providers.dart';

class SolicitarAluguelPage extends ConsumerStatefulWidget {
  final Item item;

  const SolicitarAluguelPage({super.key, required this.item});

  @override
  ConsumerState<SolicitarAluguelPage> createState() => _SolicitarAluguelPageState();
}

class _SolicitarAluguelPageState extends ConsumerState<SolicitarAluguelPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 1));
  String _observacoes = '';
  bool _alugarPorHora = false;
  int _paginaAtual = 0;
  late String _alugueId;
  late Map<String, dynamic> _dadosAluguel;
  bool _aceiteTermos = false;
  bool _aceiteResponsabilidade = false; 
  bool _aceiteCaucao = false;
  String _metodoPagamento = 'cartao';
  bool _isProcessing = false;

  bool _isAluguelIniciado = false;

  final _paginaController = PageController();
  
  @override
  void initState() {
    super.initState();
    if (widget.item.precoPorHora == null) {
      _alugarPorHora = false;
    }
    _dataInicio = DateTime.now().copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);
    _dataFim = _dataInicio.add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);

  final usuarioAsyncValue = ref.read(usuarioAtualStreamProvider);
  final locatario = usuarioAsyncValue.valueOrNull;
  final AsyncValue<ContratoDigital?> contratoState = _isAluguelIniciado ? ref.watch(contratoProvider(_alugueId)) : const AsyncValue.data(null);

  final detalhesAluguel = _calcularDetalhesAluguel();

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: theme.brightness == Brightness.light ? Brightness.dark : Brightness.light
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Solicitar Aluguel de ${widget.item.nome}',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_paginaAtual + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          )
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _paginaController,
            onPageChanged: (pagina) {
              setState(() {
                _paginaAtual = pagina;
              });
            },
            children: [
              SessaoInformacoesAluguelWidget(
                item: widget.item,
                alugarPorHora: _alugarPorHora,
                dataFim: _dataFim,
                dataInicio: _dataInicio,
                onObservacoesSaved: (value) => _observacoes = value ?? '',
                onTipoAluguelChanged: _onTipoAluguelChanged,
                selecionarData: _selecionarData,
                precoTotal: detalhesAluguel.precoTotal,
                duracaoTexto: detalhesAluguel.duracaoTexto,
              ),

              _isAluguelIniciado && _paginaAtual >= 1
                  ? AceiteContratoPage(
                      aluguelId: _alugueId,
                      dadosAluguel: _dadosAluguel,
                      aceiteTermos: _aceiteTermos,
                      aceiteResponsabilidade: _aceiteResponsabilidade,
                      aceiteCaucao: _aceiteCaucao,
                      onAceiteTermosChanged: (value) => setState(() => _aceiteTermos = value),
                      onAceiteResponsabilidadeChanged: (value) => setState(() => _aceiteResponsabilidade = value),
                      onAceiteCaucaoChanged: (value) => setState(() => _aceiteCaucao = value),
                    )
                  : const SizedBox.shrink(),

              _isAluguelIniciado && _paginaAtual >= 2
                  ? CaucaoConteudoWidget(
                      dadosAluguel: _dadosAluguel,
                      metodoPagamento: _metodoPagamento,
                      onMetodoPagamentoChanged: (novoMetodo) {
                        setState(() => _metodoPagamento = novoMetodo);
                      },
                    )
                  : const SizedBox.shrink()
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBotoesNavegacao(theme, locatario!, contratoState),
    );
  }

  Widget _buildBotoesNavegacao(ThemeData theme, Usuario locatario, AsyncValue<ContratoDigital?> contratoState) {
    String buttonText = '';
    VoidCallback? onPressedCallback;
    Widget? buttonChild;

    if (_paginaAtual == 0) {
      buttonText = 'Continuar para Contrato';
      onPressedCallback = () => _iniciarSolicitacaoAluguel(locatario);
    } else if (_paginaAtual == 1) {
      final todosAceitos = _aceiteTermos && _aceiteResponsabilidade && _aceiteCaucao;
      final bool contratoCarregado = contratoState.hasValue && contratoState.value != null;
      buttonText = 'Aceitar e Continuar';
      onPressedCallback = (todosAceitos && contratoCarregado) ? () => _handleAceitarContrato(contratoState) : null;
      buttonChild = Text(buttonText);
    } else if (_paginaAtual == 2) {
      final valorCaucao = (_dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
      onPressedCallback = _isProcessing ? null : _handleProcessarCaucao;

      if (_isProcessing) {
        buttonChild = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Processando...'),
          ],
        );
      } else {
        buttonText = valorCaucao > 0 ? 'Processar Caução - R\$ ${valorCaucao.toStringAsFixed(2)}' : 'Continuar (Sem Caução)';
        buttonChild = Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
      }
    } else {
      //TODO implementar lógica de pagamento
      buttonText = 'Finalizar Aluguel';
      onPressedCallback = _proximaPagina;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_paginaAtual > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _voltarPagina,
                child: const Text('Voltar'),
              ),
            ),
          if (_paginaAtual > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onPressedCallback,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                disabledBackgroundColor: theme.colorScheme.primary.withAlpha(153),
                foregroundColor: theme.colorScheme.onPrimary,
                disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha(153),
              ),
              child: buttonChild ?? Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  void _onTipoAluguelChanged(bool alugarPorHora) {
    setState(() {
      _alugarPorHora = alugarPorHora;
      if (alugarPorHora) {
        final now = DateTime.now().copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);
        _dataInicio = now;
        _dataFim = _dataInicio.add(const Duration(hours: 1));
      } else {
        final now = DateTime.now();
        _dataInicio = DateTime(now.year, now.month, now.day);
        _dataFim = _dataInicio.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime initialDate = isInicio ? _dataInicio : _dataFim;
    final DateTime firstDate = isInicio ? DateTime.now().subtract(const Duration(days: 1)) : _dataInicio;

    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dataSelecionada == null || !mounted) return;

    DateTime dataFinal = dataSelecionada;

    if (_alugarPorHora) {
      final TimeOfDay? horaSelecionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (horaSelecionada != null) {
        dataFinal = DateTime(
          dataSelecionada.year,
          dataSelecionada.month,
          dataSelecionada.day,
          horaSelecionada.hour,
          horaSelecionada.minute,
        );
      }
    }

    setState(() {
      if (isInicio) {
        _dataInicio = dataFinal;
        if (_dataFim.isBefore(_dataInicio)) {
          _dataFim = _dataInicio.add(_alugarPorHora ? const Duration(hours: 1) : const Duration(days: 1));
        }
      } else {
        _dataFim = dataFinal;
      }
    });
  }

  void _iniciarSolicitacaoAluguel(Usuario locatario) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final duracao = _dataFim.difference(_dataInicio);
    if (duracao.isNegative || duracao.inSeconds == 0) {
      SnackBarUtils.mostrarErro(context, 'A data de fim não pode ser anterior à data de início.');
      return;
    }

    final detalhesAluguel = _calcularDetalhesAluguel();
    final precoTotal = detalhesAluguel.precoTotal;

    if (!_isAluguelIniciado) _alugueId = FirebaseFirestore.instance.collection('alugueis').doc().id;

    _dadosAluguel = {
      'locatarioId': locatario.id,
      'nomeLocatario': locatario.nome,
      'locadorId': widget.item.proprietarioId,
      'nomeLocador': widget.item.proprietarioNome,
      'itemId': widget.item.id,
      'nomeItem': widget.item.nome,
      'itemFotoUrl': widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
      'descricaoItem': widget.item.descricao,
      'valorAluguel': precoTotal,
      'valorCaucao': widget.item.valorCaucao,
      'valorDiaria': widget.item.precoPorDia,
      'dataInicio': _dataInicio.toIso8601String(), 
      'dataFim': _dataFim.toIso8601String(), 
      'observacoesLocatario': _observacoes,
    };

    // Atualiza o estado para indicar que os dados foram criados e aciona a reconstrução do widget
    setState(() {
      _isAluguelIniciado = true;
    });

    _proximaPagina();
  }

  ({double precoTotal, String duracaoTexto}) _calcularDetalhesAluguel() {
    final duracao = _dataFim.difference(_dataInicio);

    if (_alugarPorHora && widget.item.precoPorHora != null) {
      final horas = (duracao.inMinutes / 60).ceil();
      final unidadesCobradas = horas > 0 ? horas : 1;
      final precoTotal = unidadesCobradas * widget.item.precoPorHora!;
      final duracaoTexto = '$unidadesCobradas hora(s)';
      return (precoTotal: precoTotal, duracaoTexto: duracaoTexto);
    } else {
      // Calcula os dias corretamente, arredondando para cima.
      final dias = (duracao.inHours / 24).ceil();
      final unidadesCobradas = dias > 0 ? dias : 1;
      final precoTotal = unidadesCobradas * widget.item.precoPorDia;
      final duracaoTexto = '$unidadesCobradas dia(s)';
      return (precoTotal: precoTotal, duracaoTexto: duracaoTexto);
    }
  }

  Future<void> _handleAceitarContrato(AsyncValue<ContratoDigital?> contratoState) async {
    final contrato = contratoState.value;

    if (contrato == null) {
      SnackBarUtils.mostrarErro(context, 'Contrato não carregado. Tente novamente.');
      return;
    }

    bool loadingDialogClosed = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando aceite...'),
            ],
          ),
        ),
      );

      await ref.read(contratoProvider(_alugueId).notifier).aceitarContrato(contrato.id);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogClosed = true;
      }

      SnackBarUtils.mostrarSucesso(context, 'Contrato aceito com sucesso! ✅');

      // Navegar para a próxima tela (CaucaoPage)
      if (mounted) _proximaPagina();
    } catch (e) {
      debugPrint('[SolicitarAluguelPage] Erro ao aceitar contrato: $e');
      if (mounted && !loadingDialogClosed) Navigator.of(context, rootNavigator: true).pop();
      SnackBarUtils.mostrarErro(context, 'Erro ao aceitar contrato: $e');
    }
  }

  void _voltarPagina() {
    _paginaController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _proximaPagina() {
    _paginaController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleProcessarCaucao() async {
    setState(() {
      _isProcessing = true;
    });

    final valorCaucao = (_dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
    final dataInicio = DateTime.parse(_dadosAluguel['dataInicio'] as String);
    final dataFim = DateTime.parse(_dadosAluguel['dataFim'] as String);
    final diasAluguel = (dataFim.difference(dataInicio).inDays).clamp(1, 9999);

    final String transacaoIdSimulada = 'TXN_SIM_${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (valorCaucao > 0) {
        // Simular processamento do pagamento
        await Future.delayed(const Duration(seconds: 3));
      }

      // Construir o objeto AluguelCaucao
      final caucaoDoAluguel = AluguelCaucao(
        valor: valorCaucao,
        status: valorCaucao > 0 ? StatusAluguelCaucao.bloqueada : StatusAluguelCaucao.naoAplicavel,
        metodoPagamento: valorCaucao > 0 ? _metodoPagamento : null,
        transacaoId: valorCaucao > 0 ? transacaoIdSimulada : null,
        dataBloqueio: valorCaucao > 0 ? DateTime.now() : null,
      );

      // Construir o objeto Aluguel
      final aluguelParaSalvar = Aluguel(
        id: _alugueId,
        itemId: _dadosAluguel['itemId'] as String,
        itemFotoUrl: _dadosAluguel['itemFotoUrl'] as String? ?? '',
        itemNome: _dadosAluguel['nomeItem'] as String,
        locadorId: _dadosAluguel['locadorId'] as String,
        locadorNome: _dadosAluguel['nomeLocador'] as String,
        locatarioId: _dadosAluguel['locatarioId'] as String,
        locatarioNome: _dadosAluguel['nomeLocatario'] as String,
        dataInicio: dataInicio,
        dataFim: dataFim,
        precoTotal: (_dadosAluguel['valorAluguel'] as num).toDouble(),
        status: StatusAluguel.solicitado,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        observacoesLocatario: _dadosAluguel['observacoesLocatario'] as String?,
        contratoId: _alugueId, // O ID do contrato pode ser o mesmo do aluguel
        caucao: caucaoDoAluguel,
      );

      // Salvar a solicitação de aluguel
      await ref.read(aluguelControllerProvider.notifier).submeterAluguelCompleto(aluguelParaSalvar);

      if (mounted) {
        SnackBarUtils.mostrarSucesso(
          context,
          valorCaucao > 0
              ? 'Caução processada e solicitação de aluguel enviada! 🎉'
              : 'Solicitação de aluguel enviada! 🎉',
        );

        // Navegar para status do aluguel
        final dadosParaStatus = {
          'itemId': aluguelParaSalvar.itemId,
          'nomeItem': aluguelParaSalvar.itemNome,
          'valorAluguel': aluguelParaSalvar.precoTotal,
          'valorCaucao': aluguelParaSalvar.caucao.valor,
          'dataLimiteDevolucao': aluguelParaSalvar.dataFim.toIso8601String(),
          'locadorId': aluguelParaSalvar.locadorId,
          'nomeLocador': aluguelParaSalvar.locadorNome,
          'valorDiaria':
              (_dadosAluguel['valorDiaria'] as num?)?.toDouble() ?? (aluguelParaSalvar.precoTotal / diasAluguel),
        };

        context.pushReplacement(
          '${AppRoutes.statusAluguel}/$_alugueId',
          extra: dadosParaStatus,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao processar caução: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}