import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/alugueis/domain/entities/caucao_aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/aceite_contrato_page.dart';
import 'package:coisarapida/features/alugueis/presentation/pages/caucao_page.dart'
    show CaucaoConteudoWidget;
import 'package:coisarapida/features/alugueis/presentation/widgets/sessao_informacoes_widget.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/seguranca/domain/entities/contrato.dart';
import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart';
import 'package:coisarapida/shared/providers/mercado_pago_provider.dart';
import 'package:coisarapida/shared/services/mercado_pago_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/aluguel.dart';
import '../../data/models/aluguel_model.dart';
import '../providers/aluguel_providers.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class SolicitarAluguelPage extends ConsumerStatefulWidget {
  final Item item;

  const SolicitarAluguelPage({super.key, required this.item});

  @override
  ConsumerState<SolicitarAluguelPage> createState() =>
      _SolicitarAluguelPageState();
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
  StreamSubscription? _deepLinkSubscription;
  late AppLinks _appLinks;
  
  // Flag para controlar qual tipo de pagamento está sendo processado
  bool _isPagandoCaucao = false;
  
  // ID do contrato aceito pelo locatário
  late String _contratoId;

  // Controle de fallback do pagamento
  bool _pagamentoProcessado = false;
  Timer? _timerFallback;
  String? _aluguelIdEmPagamento; // ID do aluguel em processamento
  
  // Configuração do timer de fallback (em segundos)
  static const int FALLBACK_TIMEOUT_SECONDS = 45;

  final _paginaController = PageController();

  String get _aluguelIdGerado =>
      FirebaseFirestore.instance.collection('alugueis').doc().id;

  DateTime get _agoraNormalizado => DateTime.now()
      .copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);

  Duration get _duracaoMinimaHora => const Duration(hours: 1);
  Duration get _duracaoMinimaDia => const Duration(days: 1);

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _inicializarDatas();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _timerFallback?.cancel();
    _paginaController.dispose();
    super.dispose();
  }

  void _inicializarDatas() {
    if (widget.item.precoPorHora == null) {
      _alugarPorHora = false;
    }
    _dataInicio = _agoraNormalizado;
    _dataFim = _dataInicio.add(_duracaoMinimaDia);
  }

  void _initDeepLinks() {
    // Ouvir link inicial (quando o app é aberto via deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((err) {
      debugPrint('Erro ao obter URI inicial: $err');
    });

    // Ouvir links enquanto o app está aberto
    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Erro no stream de deep links: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted || _pagamentoProcessado) return;

    debugPrint('🔗 Deep link recebido: $uri');
    debugPrint('📍 Scheme: ${uri.scheme}');
    debugPrint('📍 Path: ${uri.path}');
    debugPrint('📍 Query params: ${uri.queryParameters}');

    // Verificar se estamos realmente processando um pagamento
    // Se _dadosAluguel não foi inicializado, significa que o usuário
    // não clicou em "Pagar" ainda
    if (!_isAluguelIniciado) {
      debugPrint('⚠️ Deep link recebido mas nenhum pagamento em andamento');
      return;
    }

    if (uri.scheme != 'coisarapida') {
      debugPrint('❌ Scheme inválido: ${uri.scheme}');
      return;
    }

    // O Mercado Pago envia: coisarapida://success?params
    // Portanto, o host será 'success', 'failure' ou 'pending'
    String status = uri.host;
    
    // Validar status
    if (status.isEmpty || 
        (status != 'success' && status != 'failure' && status != 'pending')) {
      debugPrint('❌ Status inválido: $status');
      return;
    }
    final paymentId = uri.queryParameters['payment_id'];
    final collectionStatus = uri.queryParameters['collection_status'];

    debugPrint('✅ Deep link válido - Status: $status, Payment ID: $paymentId');

    switch (status) {
      case 'success':
        if (collectionStatus == 'approved') {
          debugPrint('✅ Pagamento aprovado via deep link');
          _pagamentoProcessado = true;
          _timerFallback?.cancel();
          _processarPagamentoAprovado(paymentId);
        } else {
          debugPrint('⚠️ Payment success mas status não é approved: $collectionStatus');
          SnackBarUtils.mostrarErro(
            context,
            'Pagamento pendente. Verificando status...',
          );
          setState(() => _isProcessing = false);
        }
        break;
      case 'failure':
        debugPrint('❌ Pagamento rejeitado');
        _timerFallback?.cancel();
        SnackBarUtils.mostrarErro(
          context,
          'Pagamento rejeitado. Tente novamente.',
        );
        setState(() => _isProcessing = false);
        break;
      case 'pending':
        debugPrint('⏳ Pagamento pendente');
        _timerFallback?.cancel();
        SnackBarUtils.mostrarErro(
          context,
          'Pagamento pendente. Verifique seu email para mais detalhes.',
        );
        setState(() => _isProcessing = false);
        break;
      default:
        debugPrint('❓ Status desconhecido: $status');
    }
  }

  Future<void> _processarPagamentoAprovado(String? paymentId) async {
    if (!mounted || !_isAluguelIniciado) return;

    debugPrint('💰 Processando pagamento aprovado com ID: $paymentId');

    try {
      final valorCaucao =
          (_dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
      
      _pagamentoProcessado = true;
      _timerFallback?.cancel();
      
      // Se estamos pagando a caução
      if (_isPagandoCaucao && valorCaucao > 0) {
        debugPrint('💳 Pagando caução: R\$ $valorCaucao');
        
        final caucaoDoAluguel = _criarCaucaoAluguel(
          valorCaucao,
          paymentId ?? 'MP_${DateTime.now().millisecondsSinceEpoch}',
        );

        final aluguelParaSalvar = _criarAluguelParaSalvar(caucaoDoAluguel);

        debugPrint('📝 Criado aluguel para salvar com ID: ${aluguelParaSalvar.id}');
        
        final aluguelIdCriado = await ref
            .read(aluguelControllerProvider.notifier)
            .submeterAluguelCompleto(aluguelParaSalvar);

        debugPrint('✅ Aluguel salvo com caução - ID: $aluguelIdCriado');
        
        if (mounted) {
          _mostrarSucessoENavegar(aluguelParaSalvar, valorCaucao, tipoPagamento: 'caução', aluguelIdConfirmado: aluguelIdCriado);
        }
      } 
      // Se estamos pagando o valor do aluguel (sem caução)
      else {
        debugPrint('🛒 Pagando aluguel sem caução');
        
        final caucaoDoAluguel = _criarCaucaoAluguel(0.0, null);
        final aluguelParaSalvar = _criarAluguelParaSalvar(caucaoDoAluguel);

        final aluguelIdCriado = await ref
            .read(aluguelControllerProvider.notifier)
            .submeterAluguelCompleto(aluguelParaSalvar);

        if (mounted) {
          debugPrint('✅ Aluguel salvo sem caução - ID: $aluguelIdCriado');
          _mostrarSucessoENavegar(aluguelParaSalvar, 0.0, tipoPagamento: 'aluguel', aluguelIdConfirmado: aluguelIdCriado);
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar pagamento: $e');
      debugPrint('❌ Stack trace: $e');
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao processar pagamento: $e',
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  bool _validarDatas() {
    final duracao = _dataFim.difference(_dataInicio);
    if (duracao.isNegative || duracao.inSeconds == 0) {
      SnackBarUtils.mostrarErro(
          context, 'A data de fim não pode ser anterior à data de início.');
      return false;
    }
    return true;
  }

  Future<bool> _validarDisponibilidadeItem() async {
    try {
      // Buscar aluguéis ativos (aprovados) para este item
      final alugueisAtivos = await FirebaseFirestore.instance
          .collection('alugueis')
          .where('itemId', isEqualTo: widget.item.id)
          .where('status', isEqualTo: 'aprovado')
          .get();

      // Verificar se há conflito de datas com algum aluguel ativo
      for (final doc in alugueisAtivos.docs) {
        final aluguel = AluguelModel.fromFirestore(doc);
        
        // Verificar se há sobreposição de datas
        final temConflito = _datasSeSobrepoem(
          _dataInicio, 
          _dataFim, 
          aluguel.dataInicio, 
          aluguel.dataFim
        );
        
        if (temConflito) {
          SnackBarUtils.mostrarErro(
            context, 
            'Este item já está alugado no período selecionado. '
            'Por favor, escolha outras datas.'
          );
          return false;
        }
      }
      
      return true;
    } catch (e) {
      SnackBarUtils.mostrarErro(
        context, 
        'Erro ao verificar disponibilidade do item: $e'
      );
      return false;
    }
  }

  bool _datasSeSobrepoem(DateTime inicio1, DateTime fim1, DateTime inicio2, DateTime fim2) {
    // Verifica se dois intervalos de datas se sobrepõem
    return inicio1.isBefore(fim2) && fim1.isAfter(inicio2);
  }

  Map<String, dynamic> _criarDadosAluguel(
      Usuario locatario, double precoTotal) {
    return {
      'locatarioId': locatario.id,
      'nomeLocatario': locatario.nome,
      'locadorId': widget.item.proprietarioId,
      'nomeLocador': widget.item.proprietarioNome,
      'itemId': widget.item.id,
      'nomeItem': widget.item.nome,
      'itemFotoUrl':
          widget.item.fotos.isNotEmpty ? widget.item.fotos.first : '',
      'descricaoItem': widget.item.descricao,
      'valorAluguel': precoTotal,
      'valorCaucao': widget.item.valorCaucao,
      'valorDiaria': widget.item.precoPorDia,
      'dataInicio': _dataInicio.toIso8601String(),
      'dataFim': _dataFim.toIso8601String(),
      'observacoesLocatario': _observacoes,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela

    final usuarioAsyncValue = ref.read(usuarioAtualStreamProvider);
    final locatario = usuarioAsyncValue.asData?.value;
    final AsyncValue<ContratoDigital?> contratoState = _isAluguelIniciado
        ? ref.watch(contratoProvider(_alugueId))
        : const AsyncValue.data(null);

    final detalhesAluguel = _calcularDetalhesAluguel();

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: theme.brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
            statusBarIconBrightness: theme.brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitar Aluguel',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Passo ${_paginaAtual + 1} de 3',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6.0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
                ),
              ),
              child: LinearProgressIndicator(
                value: (_paginaAtual + 1) / 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary.withOpacity(0.3),
                ),
              ),
            )),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
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
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: SessaoInformacoesAluguelWidget(
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
                  ),
                ),
              ),
              _isAluguelIniciado && _paginaAtual >= 1
                  ? AceiteContratoPage(
                      aluguelId: _alugueId,
                      dadosAluguel: _dadosAluguel,
                      aceiteTermos: _aceiteTermos,
                      aceiteResponsabilidade: _aceiteResponsabilidade,
                      aceiteCaucao: _aceiteCaucao,
                      onAceiteTermosChanged: (value) =>
                          setState(() => _aceiteTermos = value),
                      onAceiteResponsabilidadeChanged: (value) =>
                          setState(() => _aceiteResponsabilidade = value),
                      onAceiteCaucaoChanged: (value) =>
                          setState(() => _aceiteCaucao = value),
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
      bottomNavigationBar:
          _buildBotoesNavegacao(theme, locatario!, contratoState),
    );
  }

  Widget _buildBotoesNavegacao(ThemeData theme, Usuario locatario,
      AsyncValue<ContratoDigital?> contratoState) {
    final config = _getBotaoConfig(locatario, contratoState);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05; // 5% da largura da tela

    return Container(
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
      padding: EdgeInsets.all(padding),
      child: SafeArea(
        child: Row(
          children: [
            if (_paginaAtual > 0) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _voltarPagina,
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Voltar'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: padding * 0.5, vertical: padding),
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: padding),
            ],
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: config.onPressed == null
                        ? [
                            theme.colorScheme.primary.withAlpha(153),
                            theme.colorScheme.primary.withAlpha(153),
                          ]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: config.onPressed != null
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: config.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: config.child ?? Text(
                    config.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTipoAluguelChanged(bool alugarPorHora) {
    setState(() {
      _alugarPorHora = alugarPorHora;
      _dataInicio = _agoraNormalizado;
      _dataFim = _dataInicio.add(
        alugarPorHora ? _duracaoMinimaHora : _duracaoMinimaDia,
      );
    });
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime initialDate = isInicio ? _dataInicio : _dataFim;
    final DateTime firstDate = isInicio
        ? DateTime.now().subtract(const Duration(days: 1))
        : _dataInicio;

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
          _dataFim = _dataInicio.add(
            _alugarPorHora ? _duracaoMinimaHora : _duracaoMinimaDia,
          );
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

    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    if (!_validarDatas()) {
      return;
    }

    // Validar disponibilidade do item
    if (!await _validarDisponibilidadeItem()) {
      return;
    }

    final detalhesAluguel = _calcularDetalhesAluguel();
    final precoTotal = detalhesAluguel.precoTotal;

    if (!_isAluguelIniciado) _alugueId = _aluguelIdGerado;

    _dadosAluguel = _criarDadosAluguel(locatario, precoTotal);

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
      final dias = (duracao.inHours / 24).ceil();
      final unidadesCobradas = dias > 0 ? dias : 1;
      final precoTotal = unidadesCobradas * widget.item.precoPorDia;
      final duracaoTexto = '$unidadesCobradas dia(s)';
      return (precoTotal: precoTotal, duracaoTexto: duracaoTexto);
    }
  }

  Future<void> _handleAceitarContrato(
      AsyncValue<ContratoDigital?> contratoState) async {
    final contrato = contratoState.value;

    if (contrato == null) {
      SnackBarUtils.mostrarErro(
          context, 'Contrato não carregado. Tente novamente.');
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

      await ref
          .read(contratoProvider(_alugueId).notifier)
          .aceitarContrato(contrato.id);

      // Guardar o ID do contrato para usar ao submeter o aluguel
      _contratoId = contrato.id;

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogClosed = true;
      }

      SnackBarUtils.mostrarSucesso(context, 'Contrato aceito com sucesso! ✅');

      if (mounted) _proximaPagina();
    } catch (e) {
      if (mounted && !loadingDialogClosed)
        Navigator.of(context, rootNavigator: true).pop();
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

  CaucaoAluguel _criarCaucaoAluguel(double valorCaucao, String? transacaoId) {
    return CaucaoAluguel(
      valor: valorCaucao,
      status: valorCaucao > 0
          ? StatusCaucaoAluguel.bloqueada
          : StatusCaucaoAluguel.naoAplicavel,
      metodoPagamento: valorCaucao > 0 ? _metodoPagamento : null,
      transacaoId: transacaoId,
      dataBloqueio: valorCaucao > 0 ? DateTime.now() : null,
    );
  }

  Aluguel _criarAluguelParaSalvar(CaucaoAluguel caucao) {
    final dataInicio = DateTime.parse(_dadosAluguel['dataInicio'] as String);
    final dataFim = DateTime.parse(_dadosAluguel['dataFim'] as String);

    return Aluguel(
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
      contratoId: _contratoId,
      caucao: caucao,
    );
  }

  void _handleIniciarPagamento() async {
    setState(() => _isProcessing = true);

    final valorCaucao =
        (_dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
    final valorAluguel =
        (_dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0;

    try {
      // Obter dados do usuário
      final usuarioAsyncValue = ref.read(usuarioAtualStreamProvider);
      final usuario = usuarioAsyncValue.asData?.value;

      if (usuario == null) {
        throw Exception('Usuário não autenticado');
      }

      final mercadoPagoService = ref.read(mercadoPagoServiceProvider);
      
      // Se há caução, processar pagamento da caução
      if (valorCaucao > 0) {
        setState(() => _isPagandoCaucao = true);
        
        final preferenceResponse = await mercadoPagoService.criarPreferenciaPagamento(
          aluguelId: _alugueId,
          valor: valorCaucao,
          itemNome: 'Caução - ${_dadosAluguel['nomeItem']}',
          itemDescricao: 'Caução para aluguel de ${_dadosAluguel['nomeItem']}',
          locatarioId: usuario.id,
          locatarioEmail: usuario.email,
          tipo: TipoTransacao.caucao,
          locatarioNome: usuario.nome,
          locatarioTelefone: usuario.telefone,
        );

        if (!mounted) return;
        //SIMULAÇÃO: Em vez de abrir checkout, chama sucesso diretamente
        // await _processarPagamentoAprovado('SIMULADO_${DateTime.now().millisecondsSinceEpoch}');
        // TODO voltar ao Mercado Pago, descomente a linha abaixo e comente a acima:
        await _abrirCheckoutMercadoPago(preferenceResponse);
      } 
      // Se não há caução, processar pagamento do valor do aluguel
      else {
        setState(() => _isPagandoCaucao = false);
        
        final preferenceResponse = await mercadoPagoService.criarPreferenciaPagamento(
          aluguelId: _alugueId,
          valor: valorAluguel,
          itemNome: 'Aluguel - ${_dadosAluguel['nomeItem']}',
          itemDescricao: 'Pagamento do aluguel de ${_dadosAluguel['nomeItem']}',
          locatarioId: usuario.id,
          locatarioEmail: usuario.email,
          tipo: TipoTransacao.aluguel,
          locatarioNome: usuario.nome,
          locatarioTelefone: usuario.telefone,
        );
        
        if (!mounted) return;
         //SIMULAÇÃO: Em vez de abrir checkout, chama sucesso diretamente
        // await _processarPagamentoAprovado('SIMULADO_${DateTime.now().millisecondsSinceEpoch}');
        // TODO voltar ao Mercado Pago, descomente a linha abaixo e comente a acima:
        await _abrirCheckoutMercadoPago(preferenceResponse);
      }

    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao iniciar pagamento: $e',
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _abrirCheckoutMercadoPago(Map<String, dynamic> checkoutResponse) async {
    final theme = Theme.of(context);
    final initPoint = checkoutResponse['init_point'] as String;
    final aluguelId = checkoutResponse['aluguelId'] as String?;
    
    try {
      // Armazenar ID do aluguel em pagamento para fallback
      _aluguelIdEmPagamento = aluguelId;
      
      debugPrint('🛒 Abrindo checkout: $initPoint');
      debugPrint('💳 Aluguel em pagamento: $_aluguelIdEmPagamento');
      
      // Iniciar timer de fallback
      _iniciarTimerFallback();
      
      await launchUrl(
        Uri.parse(initPoint),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: theme.colorScheme.primary,
            navigationBarColor: theme.colorScheme.surface,
          ),
          shareState: CustomTabsShareState.off,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: CustomTabsCloseButton(
            icon: CustomTabsCloseButtonIcons.back,
          ),
          animations: const CustomTabsAnimations(
            startEnter: 'slide_up',
            startExit: 'android:anim/fade_out',
            endEnter: 'android:anim/fade_in',
            endExit: 'slide_down',
          ),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: theme.colorScheme.primary,
          preferredControlTintColor: theme.colorScheme.onPrimary,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
      
      // Nota: O retorno será tratado pelo deep link em _handleDeepLink
      // Se o deep link não chegar, o timer de fallback verificará o status
      
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Erro ao abrir checkout: $e');
        SnackBarUtils.mostrarErro(
          context,
          'Erro ao abrir checkout: $e. Verifique se há um navegador instalado.',
        );
        setState(() => _isProcessing = false);
        _timerFallback?.cancel();
      }
    }
  }

  /// Inicia um timer para verificar o status do pagamento após FALLBACK_TIMEOUT_SECONDS
  /// Isso funciona como fallback se o deep link não funcionar
  void _iniciarTimerFallback() {
    _timerFallback?.cancel(); // Cancela qualquer timer anterior
    
    debugPrint('⏱️ Iniciando timer de fallback (${FALLBACK_TIMEOUT_SECONDS}s)');
    
    _timerFallback = Timer(const Duration(seconds: FALLBACK_TIMEOUT_SECONDS), () async {
      if (!mounted || _pagamentoProcessado) {
        debugPrint('✅ Pagamento já foi processado ou widget desmontado');
        return;
      }

      debugPrint('⏰ Timer de fallback acionado! Deep link não retornou.');
      
      try {
        if (_aluguelIdEmPagamento == null) {
          debugPrint('❌ Aluguel ID não disponível');
          setState(() => _isProcessing = false);
          return;
        }

        debugPrint('⚠️ Deep link não foi recebido em ${FALLBACK_TIMEOUT_SECONDS}s');
        
        // Fallback: Avisar usuário para verificar email e tentar recarregar
        SnackBarUtils.mostrarErro(
          context,
          'Pagamento pode ter sido processado. Verifique seu email e reabra o app.',
        );
        
        setState(() => _isProcessing = false);
        
        // Opcionalmente: Pode implementar webhook do Mercado Pago para resolver isso depois
        debugPrint('💡 Nota: Configure webhook do Mercado Pago para confirmar pagamentos automaticamente');
        
      } catch (e) {
        if (mounted) {
          debugPrint('❌ Erro no fallback: $e');
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  void _mostrarSucessoENavegar(Aluguel aluguel, double valorCaucao, {String tipoPagamento = '', String? aluguelIdConfirmado}) {
    String mensagem;
    
    if (tipoPagamento == 'caução') {
      mensagem = 'Caução processada e solicitação de aluguel enviada! 🎉';
    } else if (tipoPagamento == 'aluguel') {
      mensagem = 'Pagamento realizado e solicitação de aluguel enviada! 🎉';
    } else {
      mensagem = valorCaucao > 0
          ? 'Caução processada e solicitação de aluguel enviada! 🎉'
          : 'Solicitação de aluguel enviada! 🎉';
    }
    
    SnackBarUtils.mostrarSucesso(context, mensagem);

    // Usar o ID confirmado do backend se disponível, senão usar o ID do aluguel
    final finalAluguelId = aluguelIdConfirmado ?? aluguel.id;
    
    // Usar context.go() para navegar e limpar o stack de rotas
    // Usar o aluguel.id que foi retornado do backend
    context.go(
      '${AppRoutes.statusAluguel}/$finalAluguelId',
    );
  }

  ({String text, VoidCallback? onPressed, Widget? child}) _getBotaoConfig(
    Usuario locatario,
    AsyncValue<ContratoDigital?> contratoState,
  ) {
    switch (_paginaAtual) {
      case 0:
        return (
          text: 'Continuar para Contrato',
          onPressed: () => _iniciarSolicitacaoAluguel(locatario),
          child: null,
        );
      case 1:
        final todosAceitos =
            _aceiteTermos && _aceiteResponsabilidade && _aceiteCaucao;
        final contratoCarregado =
            contratoState.hasValue && contratoState.value != null;
        return (
          text: 'Aceitar e Continuar',
          onPressed: (todosAceitos && contratoCarregado)
              ? () => _handleAceitarContrato(contratoState)
              : null,
          child: null,
        );
      case 2:
        return _getCaucaoBotaoConfig();
      default:
        return (
          text: 'Finalizar Aluguel',
          onPressed: _proximaPagina,
          child: null,
        );
    }
  }

  Widget _buildBotaoProcessando() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('Processando...'),
      ],
    );
  }

  ({String text, VoidCallback? onPressed, Widget? child})
      _getCaucaoBotaoConfig() {
    final valorCaucao = (_dadosAluguel['valorCaucao'] as num?)?.toDouble() ?? 0.0;
    final valorAluguel = (_dadosAluguel['valorAluguel'] as num?)?.toDouble() ?? 0.0;
    
    if (_isProcessing) {
      return (
        text: '',
        onPressed: null,
        child: _buildBotaoProcessando(),
      );
    } else {
      final textoBotao = valorCaucao > 0
          ? 'Pagar - R\$ ${valorCaucao.toStringAsFixed(2)}'
          : 'Pagar - R\$ ${valorAluguel.toStringAsFixed(2)}';
          
      return (
        text: textoBotao,
        onPressed: _handleIniciarPagamento,
        child: Text(
          textoBotao,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}
