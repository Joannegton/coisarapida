import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../../../autenticacao/presentation/widgets/campo_texto_customizado.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela para criar nova entrega
class NovaEntregaPage extends ConsumerStatefulWidget {
  const NovaEntregaPage({super.key});

  @override
  ConsumerState<NovaEntregaPage> createState() => _NovaEntregaPageState();
}

class _NovaEntregaPageState extends ConsumerState<NovaEntregaPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controladores dos campos
  final _remetenteNomeController = TextEditingController();
  final _remetenteTelefoneController = TextEditingController();
  final _remetenteEnderecoController = TextEditingController();
  
  final _destinatarioNomeController = TextEditingController();
  final _destinatarioTelefoneController = TextEditingController();
  final _destinatarioEnderecoController = TextEditingController();
  
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  int _paginaAtual = 0;
  String _tipoEntrega = 'documento';
  String _urgencia = 'normal';
  bool _seguro = false;
  
  @override
  void dispose() {
    _remetenteNomeController.dispose();
    _remetenteTelefoneController.dispose();
    _remetenteEnderecoController.dispose();
    _destinatarioNomeController.dispose();
    _destinatarioTelefoneController.dispose();
    _destinatarioEnderecoController.dispose();
    _descricaoController.dispose();
    _observacoesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Entrega'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_paginaAtual + 1) / 4,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (pagina) {
            setState(() {
              _paginaAtual = pagina;
            });
          },
          children: [
            _buildPaginaRemetente(),
            _buildPaginaDestinatario(),
            _buildPaginaDetalhes(),
            _buildPaginaResumo(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotoesNavegacao(theme),
    );
  }

  Widget _buildPaginaRemetente() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Remetente',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quem está enviando a entrega?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          CampoTextoCustomizado(
            controller: _remetenteNomeController,
            label: 'Nome completo',
            hint: 'Digite o nome do remetente',
            prefixIcon: Icons.person,
            validator: Validatorless.required('Nome é obrigatório'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _remetenteTelefoneController,
            label: 'Telefone',
            hint: '(11) 99999-9999',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: Validatorless.required('Telefone é obrigatório'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _remetenteEnderecoController,
            label: 'Endereço completo',
            hint: 'Rua, número, bairro, cidade',
            prefixIcon: Icons.location_on,
            maxLines: 3,
            validator: Validatorless.required('Endereço é obrigatório'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaDestinatario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Destinatário',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para quem será entregue?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          CampoTextoCustomizado(
            controller: _destinatarioNomeController,
            label: 'Nome completo',
            hint: 'Digite o nome do destinatário',
            prefixIcon: Icons.person,
            validator: Validatorless.required('Nome é obrigatório'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _destinatarioTelefoneController,
            label: 'Telefone',
            hint: '(11) 99999-9999',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: Validatorless.required('Telefone é obrigatório'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _destinatarioEnderecoController,
            label: 'Endereço completo',
            hint: 'Rua, número, bairro, cidade',
            prefixIcon: Icons.location_on,
            maxLines: 3,
            validator: Validatorless.required('Endereço é obrigatório'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaDetalhes() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da Entrega',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O que será entregue?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Tipo de entrega
          Text(
            'Tipo de entrega',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            children: [
              _buildChipTipo('documento', 'Documento', Icons.description),
              _buildChipTipo('encomenda', 'Encomenda', Icons.inventory),
              _buildChipTipo('medicamento', 'Medicamento', Icons.medical_services),
              _buildChipTipo('comida', 'Comida', Icons.restaurant),
            ],
          ),
          
          const SizedBox(height: 24),
          
          CampoTextoCustomizado(
            controller: _descricaoController,
            label: 'Descrição do item',
            hint: 'Descreva o que será entregue',
            prefixIcon: Icons.description,
            maxLines: 2,
            validator: Validatorless.required('Descrição é obrigatória'),
          ),
          
          const SizedBox(height: 24),
          
          // Urgência
          Text(
            'Urgência',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('Normal'),
                subtitle: const Text('Entrega em até 24h - Grátis'),
                value: 'normal',
                groupValue: _urgencia,
                onChanged: (valor) {
                  setState(() {
                    _urgencia = valor!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Expressa'),
                subtitle: const Text('Entrega em até 4h - R\$ 5,00'),
                value: 'expressa',
                groupValue: _urgencia,
                onChanged: (valor) {
                  setState(() {
                    _urgencia = valor!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Urgente'),
                subtitle: const Text('Entrega em até 1h - R\$ 15,00'),
                value: 'urgente',
                groupValue: _urgencia,
                onChanged: (valor) {
                  setState(() {
                    _urgencia = valor!;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seguro
          SwitchListTile(
            title: const Text('Contratar seguro'),
            subtitle: const Text('Proteção contra danos - R\$ 2,00'),
            value: _seguro,
            onChanged: (valor) {
              setState(() {
                _seguro = valor;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _observacoesController,
            label: 'Observações (opcional)',
            hint: 'Instruções especiais para o entregador',
            prefixIcon: Icons.note,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaResumo() {
    final theme = Theme.of(context);
    final valorBase = _calcularValorBase();
    final valorTotal = _calcularValorTotal();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da Entrega',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirme os dados antes de solicitar',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Remetente
          _buildCardResumo(
            'Remetente',
            [
              _remetenteNomeController.text,
              _remetenteTelefoneController.text,
              _remetenteEnderecoController.text,
            ],
            Icons.person,
          ),
          
          const SizedBox(height: 16),
          
          // Destinatário
          _buildCardResumo(
            'Destinatário',
            [
              _destinatarioNomeController.text,
              _destinatarioTelefoneController.text,
              _destinatarioEnderecoController.text,
            ],
            Icons.location_on,
          ),
          
          const SizedBox(height: 16),
          
          // Detalhes
          _buildCardResumo(
            'Detalhes',
            [
              'Tipo: ${_obterNomeTipo(_tipoEntrega)}',
              'Descrição: ${_descricaoController.text}',
              'Urgência: ${_obterNomeUrgencia(_urgencia)}',
              if (_seguro) 'Seguro: Contratado',
              if (_observacoesController.text.isNotEmpty)
                'Obs: ${_observacoesController.text}',
            ],
            Icons.inventory,
          ),
          
          const SizedBox(height: 24),
          
          // Valores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valores',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildItemValor('Entrega base', 'R\$ ${valorBase.toStringAsFixed(2)}'),
                  if (_urgencia == 'expressa')
                    _buildItemValor('Taxa expressa', 'R\$ 5,00'),
                  if (_urgencia == 'urgente')
                    _buildItemValor('Taxa urgente', 'R\$ 15,00'),
                  if (_seguro)
                    _buildItemValor('Seguro', 'R\$ 2,00'),
                  
                  const Divider(),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R\$ ${valorTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTipo(String valor, String label, IconData icone) {
    final isSelected = _tipoEntrega == valor;
    final theme = Theme.of(context);
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _tipoEntrega = valor;
        });
      },
      avatar: Icon(
        icone,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
        size: 18,
      ),
      label: Text(label),
      backgroundColor: isSelected ? theme.colorScheme.primary : null,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildCardResumo(String titulo, List<String> itens, IconData icone) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...itens.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildItemValor(String descricao, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(descricao),
          Text(valor),
        ],
      ),
    );
  }

  Widget _buildBotoesNavegacao(ThemeData theme) {
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
              onPressed: _paginaAtual == 3 ? _confirmarEntrega : _proximaPagina,
              child: Text(_paginaAtual == 3 ? 'Confirmar Entrega' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  void _voltarPagina() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _proximaPagina() {
    if (_validarPaginaAtual()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validarPaginaAtual() {
    switch (_paginaAtual) {
      case 0:
        return _remetenteNomeController.text.isNotEmpty &&
               _remetenteTelefoneController.text.isNotEmpty &&
               _remetenteEnderecoController.text.isNotEmpty;
      case 1:
        return _destinatarioNomeController.text.isNotEmpty &&
               _destinatarioTelefoneController.text.isNotEmpty &&
               _destinatarioEnderecoController.text.isNotEmpty;
      case 2:
        return _descricaoController.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _confirmarEntrega() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Entrega'),
          content: Text(
            'Deseja confirmar a solicitação de entrega por R\$ ${_calcularValorTotal().toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processarEntrega();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    }
  }

  void _processarEntrega() {
    // Simular processamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processando entrega...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Fechar dialog de loading
      
      SnackBarUtils.mostrarSucesso(
        context,
        'Entrega solicitada com sucesso! Código: CR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      );
      
      context.pop(); // Voltar para tela anterior
    });
  }

  double _calcularValorBase() {
    switch (_tipoEntrega) {
      case 'documento':
        return 8.0;
      case 'encomenda':
        return 12.0;
      case 'medicamento':
        return 10.0;
      case 'comida':
        return 15.0;
      default:
        return 8.0;
    }
  }

  double _calcularValorTotal() {
    double total = _calcularValorBase();
    
    if (_urgencia == 'expressa') total += 5.0;
    if (_urgencia == 'urgente') total += 15.0;
    if (_seguro) total += 2.0;
    
    return total;
  }

  String _obterNomeTipo(String tipo) {
    switch (tipo) {
      case 'documento':
        return 'Documento';
      case 'encomenda':
        return 'Encomenda';
      case 'medicamento':
        return 'Medicamento';
      case 'comida':
        return 'Comida';
      default:
        return 'Documento';
    }
  }

  String _obterNomeUrgencia(String urgencia) {
    switch (urgencia) {
      case 'normal':
        return 'Normal (até 24h)';
      case 'expressa':
        return 'Expressa (até 4h)';
      case 'urgente':
        return 'Urgente (até 1h)';
      default:
        return 'Normal';
    }
  }
}
