import 'package:flutter/material.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import '../services/melhor_envio_service.dart';

enum TipoEntrega {
  pessoalmente,
  correios,
  uberEntregas,
}

class TipoEntregaCard extends StatelessWidget {
  final TipoEntrega tipo;
  final bool isSelected;
  final VoidCallback? onTap;

  const TipoEntregaCard({
    super.key,
    required this.tipo,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardSize = 50.0;
    final iconSize = 30.0;

    final (icone, nome, cor) = switch (tipo) {
      TipoEntrega.pessoalmente => (
          Icons.handshake,
          'Pessoalmente',
          Colors.green
        ),
      TipoEntrega.correios => (
          Icons.local_shipping,
          'Correios',
          Colors.blue
        ),
      TipoEntrega.uberEntregas => (
          Icons.delivery_dining,
          'Uber Entregas',
          Colors.orange
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: isSelected
                  ? cor
                  : cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: cor,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icone,
              color: isSelected ? Colors.white : cor.withValues(alpha: 0.7),
              size: iconSize,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? cor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SelecaoTipoEntrega extends StatefulWidget {
  final TipoEntrega? tipoSelecionado;
  final ValueChanged<TipoEntrega?>? onTipoSelecionado;
  final Endereco? origem; // vendedor
  final Endereco? destino; // comprador
  final Item? item;

  const SelecaoTipoEntrega({
    super.key,
    this.tipoSelecionado,
    this.onTipoSelecionado,
    this.origem,
    this.destino,
    this.item,
  });

  @override
  State<SelecaoTipoEntrega> createState() => _SelecaoTipoEntregaState();
}

class _SelecaoTipoEntregaState extends State<SelecaoTipoEntrega> {
  TipoEntrega? _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoSelecionado;
  }

  @override
  void didUpdateWidget(SelecaoTipoEntrega oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tipoSelecionado != widget.tipoSelecionado) {
      _tipoSelecionado = widget.tipoSelecionado;
    }
  }

  void _onTipoTap(TipoEntrega tipo) {
    switch (tipo) {
      case TipoEntrega.pessoalmente:
        _mostrarDialogoPessoalmente();
        break;
      case TipoEntrega.uberEntregas:
        _abrirUberEntregas();
        break;
      case TipoEntrega.correios:
        _mostrarBottomSheetCorreios();
        break;
    }
  }

  void _mostrarDialogoPessoalmente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Entrega Pessoalmente'),
        content: const Text(
          'Você combinará a entrega com o vendedor através de mensagem direta após confirmar a compra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _tipoSelecionado = TipoEntrega.pessoalmente);
              widget.onTipoSelecionado?.call(TipoEntrega.pessoalmente);
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _abrirUberEntregas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Uber Entregas'),
        content: const Text(
          'Você será redirecionado ao app da Uber após finalizar o pagamento para solicitar um entregador.',
        ),
        actions: [
          TextButton(
            onPressed: () => {
              setState(() => _tipoSelecionado = TipoEntrega.uberEntregas),
              widget.onTipoSelecionado?.call(TipoEntrega.uberEntregas),
              Navigator.pop(context)
            },
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _mostrarBottomSheetCorreios() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: CorreiosBottomSheet(
          cepOrigem: widget.origem?.cep,
          cepDestino: widget.destino?.cep,
          item: widget.item,
          enderecoOrigem: widget.origem,
          enderecoDestino: widget.destino,
          onConfirm: (tipoFrete, valor, prazo) {
            setState(() => _tipoSelecionado = TipoEntrega.correios);
            widget.onTipoSelecionado?.call(TipoEntrega.correios);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como deseja receber?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: TipoEntrega.values.map((tipo) {
              return TipoEntregaCard(
                tipo: tipo,
                isSelected: _tipoSelecionado == tipo,
                onTap: () => _onTipoTap(tipo),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet para seleção de tipo de frete via Melhor Envio
class CorreiosBottomSheet extends StatefulWidget {
  final Function(String tipoFrete, double valor, int prazo) onConfirm;
  final String? cepOrigem;
  final String? cepDestino;
  final Item? item;
  final Endereco? enderecoOrigem;
  final Endereco? enderecoDestino;

  const CorreiosBottomSheet({
    super.key,
    required this.onConfirm,
    this.cepOrigem,
    this.cepDestino,
    this.item,
    this.enderecoOrigem,
    this.enderecoDestino,
  });

  @override
  State<CorreiosBottomSheet> createState() => _CorreiosBottomSheetState();
}

class _CorreiosBottomSheetState extends State<CorreiosBottomSheet> {
  late Endereco _enderecoDestino;
  final _cepDestinoController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  
  String? _tipoFreteSelecionado;
  List<dynamic> _fretesCalculados = [];
  bool _isLoading = false;
  bool _mostraFormulario = false;
  bool _preenchendoCep = false;

  @override
  void dispose() {
    _cepDestinoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _enderecoDestino = widget.enderecoDestino ?? const Endereco(
      cep: '',
      rua: '',
      numero: '',
      bairro: '',
      cidade: '',
      estado: '',
    );
    _cepDestinoController.text = _enderecoDestino.cep;
    _ruaController.text = _enderecoDestino.rua;
    _numeroController.text = _enderecoDestino.numero;
    _complementoController.text = _enderecoDestino.complemento ?? '';
    _bairroController.text = _enderecoDestino.bairro;
    _cidadeController.text = _enderecoDestino.cidade;
    _estadoController.text = _enderecoDestino.estado;
    
    // Calcular automaticamente ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) => _calcularFretes());
  }

  Future<void> _calcularFretes() async {
    setState(() {
      _isLoading = true;
      _tipoFreteSelecionado = null;
    });

    try {
      if (widget.enderecoOrigem == null || widget.item == null) {
        throw Exception('Dados faltando para cálculo');
      }

      final fretes = await MelhorEnvioService.calcularFrete(
        origem: widget.enderecoOrigem!,
        destino: _enderecoDestino,
        item: widget.item!,
      );

      setState(() {
        _fretesCalculados = fretes.entries.map((entry) {
          return FreteMelhorEnvio.fromJson(entry.key, entry.value);
        }).toList();
        _mostraFormulario = false;
      });
    } catch (e) {
      print('Erro ao calcular frete: $e');
      setState(() {
        _fretesCalculados = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _abrirFormularioEndereco() {
    setState(() => _mostraFormulario = true);
  }

  Future<void> _preencherEnderecoByCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cepLimpo.length != 8) {
      return; // CEP inválido, não faz nada
    }

    setState(() => _preenchendoCep = true);

    try {
      final resultado = await MelhorEnvioService.buscarEnderecoPorCep(cepLimpo);
      
      if (resultado['success'] == true && resultado['endereco'] != null) {
        final endereco = resultado['endereco'];
        setState(() {
          _ruaController.text = endereco['logradouro'] ?? '';
          _bairroController.text = endereco['bairro'] ?? '';
          _cidadeController.text = endereco['cidade'] ?? '';
          _estadoController.text = endereco['uf'] ?? '';
          _complementoController.text = endereco['complemento'] ?? '';
          // Deixar número vazio para o usuário preencher
          _numeroController.text = '';
        });
      }
    } catch (e) {
      print('Erro ao buscar endereço: $e');
    } finally {
      setState(() => _preenchendoCep = false);
    }
  }

  void _atualizarEndereco() {
    final novoCep = _cepDestinoController.text.replaceAll('-', '');
    if (novoCep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP inválido')),
      );
      return;
    }

    // Atualizar endereço com novo CEP
    setState(() {
      _enderecoDestino = _enderecoDestino.copyWith(
        cep: _cepDestinoController.text,
        rua: _ruaController.text,
        numero: _numeroController.text,
        complemento: _complementoController.text.isEmpty ? null : _complementoController.text,
        bairro: _bairroController.text,
        cidade: _cidadeController.text,
        estado: _estadoController.text,
      );
    });

    _calcularFretes();
  }

  static String _formatarCep(String cep) {
    final limpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpo.length == 8) {
      return '${limpo.substring(0, 5)}-${limpo.substring(5)}';
    }
    return cep;
  }

  void _onCepChanged(String value) {
    final formatted = _formatarCep(value);
    if (formatted != value) {
      _cepDestinoController.text = formatted;
      _cepDestinoController.selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }

    // Se o CEP foi completamente preenchido, buscar endereço automaticamente
    final cepLimpo = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length == 8) {
      _preencherEnderecoByCep(cepLimpo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arraste
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Opções de Entrega',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Formulário de endereço (expandível)
            if (_mostraFormulario) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mudar local de entrega',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                    
                    // Campo CEP
                    TextField(
                      controller: _cepDestinoController,
                      decoration: InputDecoration(
                        labelText: 'CEP *',
                        hintText: '00000-000',
                        border: const OutlineInputBorder(),
                        suffixIcon: _preenchendoCep
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onCepChanged,
                      enabled: !_preenchendoCep && !_isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Campo Rua
                    TextField(
                      controller: _ruaController,
                      decoration: const InputDecoration(
                        labelText: 'Rua *',
                        hintText: 'Nome da rua',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Campos Número e Complemento
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _numeroController,
                            decoration: const InputDecoration(
                              labelText: 'Nº *',
                              hintText: '000',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _complementoController,
                            decoration: const InputDecoration(
                              labelText: 'Complemento',
                              hintText: 'Apto, bloco, etc',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Campo Bairro
                    TextField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        labelText: 'Bairro *',
                        hintText: 'Nome do bairro',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Campos Cidade e Estado
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _cidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Cidade *',
                              hintText: 'Nome da cidade',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _estadoController,
                            decoration: const InputDecoration(
                              labelText: 'Estado *',
                              hintText: 'SP',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            enabled: !_isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _mostraFormulario = false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading || _preenchendoCep ? null : _atualizarEndereco,
                            child: const Text('Calcular'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],

            // Loading
            if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Calculando fretes...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_fretesCalculados.isEmpty) ...[
              // Sem fretes disponíveis
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sem opções disponíveis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Os serviços não estão disponíveis para esta rota.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!_mostraFormulario)
                      ElevatedButton.icon(
                        onPressed: _abrirFormularioEndereco,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Mudar local entrega'),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Lista de fretes
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _fretesCalculados.map((frete) {
                      final isSelected = _tipoFreteSelecionado == frete.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _tipoFreteSelecionado = frete.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Text(frete.icone, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          frete.nome,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          frete.valorFormatado,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      frete.descricao,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Prazo: ${frete.prazoFormatado}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botão mudar local (só mostra quando não está no formulário)
              if (!_mostraFormulario)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirFormularioEndereco,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Mudar local entrega'),
                  ),
                ),
              if (!_mostraFormulario)
                const SizedBox(height: 12),
            ],

            // Botões de ação (sempre na base)
            if (!_mostraFormulario && _fretesCalculados.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _tipoFreteSelecionado != null && !_isLoading
                          ? () {
                              final freteSelecionado = _fretesCalculados
                                  .firstWhere((frete) => frete.id == _tipoFreteSelecionado);
                              widget.onConfirm(
                                freteSelecionado.id,
                                freteSelecionado.valor,
                                freteSelecionado.prazo,
                              );
                            }
                          : null,
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
