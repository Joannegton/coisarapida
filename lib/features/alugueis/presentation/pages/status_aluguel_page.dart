import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

// import '../../../seguranca/presentation/providers/seguranca_provider.dart'; // SegurancaRepository ainda é usado para multa e denúncia
import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart'; // Para denunciaProvider e segurancaRepositoryProvider
import '../../../seguranca/presentation/widgets/contador_tempo.dart';
import '../../../seguranca/presentation/widgets/upload_fotos_verificacao.dart';
import '../../../seguranca/domain/entities/denuncia.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela de status do aluguel com funcionalidades de segurança
class StatusAluguelPage extends ConsumerStatefulWidget {
  final String aluguelId;
  final Map<String, dynamic> dadosAluguel;

  const StatusAluguelPage({
    super.key,
    required this.aluguelId,
    required this.dadosAluguel,
  });

  @override
  ConsumerState<StatusAluguelPage> createState() => _StatusAluguelPageState();
}

class _StatusAluguelPageState extends ConsumerState<StatusAluguelPage> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Verificar se há atraso e calcular multa
      _verificarAtraso();
    });
  }

  void _verificarAtraso() async {
    final dataLimite = DateTime.parse(widget.dadosAluguel['dataLimiteDevolucao']);
    final agora = DateTime.now();
    
    if (agora.isAfter(dataLimite)) {
      // Calcular multa por atraso
      final repository = ref.read(segurancaRepositoryProvider);
      final multa = await repository.calcularMultaAtraso(
        aluguelId: widget.aluguelId,
        dataLimiteDevolucao: dataLimite,
        valorDiaria: double.parse(widget.dadosAluguel['valorDiaria'].toString()),
      );
      
      if (multa > 0 && mounted) {
        SnackBarUtils.mostrarAviso(
          context,
          'Multa por atraso: R\$ ${multa.toStringAsFixed(2)} ⚠️',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataLimite = DateTime.parse(widget.dadosAluguel['dataLimiteDevolucao']);
    final agora = DateTime.now();
    final emAtraso = agora.isAfter(dataLimite);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do Aluguel'),
        backgroundColor: emAtraso ? Colors.red[100] : theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status do item
            _buildStatusCard(theme, emAtraso),
            
            const SizedBox(height: 16),
            
            // Contador de tempo
            ContadorTempo(
              dataLimite: dataLimite,
              onAtraso: () => _verificarAtraso(),
            ),
            
            const SizedBox(height: 16),
            
            // Informações do aluguel
            _buildInformacoesAluguel(theme),
            
            const SizedBox(height: 16),
            
            // Upload de fotos de verificação
            UploadFotosVerificacao(
              aluguelId: widget.aluguelId,
              itemId: widget.dadosAluguel['itemId'],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            _buildBotoesAcao(theme, emAtraso),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool emAtraso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emAtraso ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emAtraso ? Colors.red[300]! : Colors.green[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            emAtraso ? Icons.warning : Icons.check_circle,
            size: 48,
            color: emAtraso ? Colors.red[600] : Colors.green[600],
          ),
          const SizedBox(height: 8),
          Text(
            emAtraso ? 'ALUGUEL EM ATRASO' : 'ALUGUEL ATIVO',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: emAtraso ? Colors.red[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emAtraso 
                ? 'Devolva o item o quanto antes para evitar multas'
                : 'Lembre-se de devolver no prazo combinado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emAtraso ? Colors.red[600] : Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInformacoesAluguel(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Aluguel',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow('Item:', widget.dadosAluguel['nomeItem']),
            _buildInfoRow('Locador:', widget.dadosAluguel['nomeLocador']),
            _buildInfoRow('Valor:', 'R\$ ${widget.dadosAluguel['valorAluguel']}'),
            _buildInfoRow('Caução:', 'R\$ ${widget.dadosAluguel['valorCaucao']}'),
            _buildInfoRow(
              'Data Limite:', 
              _formatarData(DateTime.parse(widget.dadosAluguel['dataLimiteDevolucao'])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao(ThemeData theme, bool emAtraso) {
    return Column(
      children: [
        // Botão de confirmar devolução
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmarDevolucao,
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmar Devolução'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botão de denunciar problema
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _abrirDenuncia,
            icon: const Icon(Icons.report_problem),
            label: const Text('Reportar Problema'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[600],
              side: BorderSide(color: Colors.orange[600]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botão de chat com locador
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _abrirChat,
            icon: const Icon(Icons.chat),
            label: const Text('Conversar com Locador'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmarDevolucao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Devolução'),
        content: const Text(
          'Você confirma que devolveu o item em perfeitas condições? '
          'Esta ação liberará a caução após aprovação do locador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processarDevolucao();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _processarDevolucao() async {
    try {
      // Simular processo de devolução
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando devolução...'),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Devolução confirmada! Aguarde aprovação do locador. ✅',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao processar devolução: $e');
      }
    }
  }

  void _abrirDenuncia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormularioDenuncia(
        aluguelId: widget.aluguelId,
        dadosAluguel: widget.dadosAluguel,
      ),
    );
  }

  void _abrirChat() {
    // Navegar para chat com o locador
    // context.push('/chat/${widget.dadosAluguel['locadorId']}');
    SnackBarUtils.mostrarInfo(context, 'Abrindo chat com locador...');
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Widget para formulário de denúncia
class _FormularioDenuncia extends ConsumerStatefulWidget {
  final String aluguelId;
  final Map<String, dynamic> dadosAluguel;

  const _FormularioDenuncia({
    required this.aluguelId,
    required this.dadosAluguel,
  });

  @override
  ConsumerState<_FormularioDenuncia> createState() => _FormularioDenunciaState();
}

class _FormularioDenunciaState extends ConsumerState<_FormularioDenuncia> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  TipoDenuncia _tipoSelecionado = TipoDenuncia.outros;
  final List<File> _evidencias = [];

  final Map<TipoDenuncia, String> _tiposDescricao = {
    TipoDenuncia.naoDevolucao: 'Não devolução do item',
    TipoDenuncia.atraso: 'Atraso na devolução',
    TipoDenuncia.danos: 'Danos no item',
    TipoDenuncia.usoIndevido: 'Uso indevido do item',
    TipoDenuncia.comportamentoInadequado: 'Comportamento inadequado',
    TipoDenuncia.outros: 'Outros problemas',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.report_problem, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Reportar Problema',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tipo de problema
            Text(
              'Tipo do problema:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<TipoDenuncia>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _tiposDescricao.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  _tipoSelecionado = valor!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            Text(
              'Descrição detalhada:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descreva o problema em detalhes...',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Descrição é obrigatória';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Evidências
            Text(
              'Evidências (fotos):',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _evidencias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                          const SizedBox(height: 4),
                          Text(
                            'Adicionar fotos',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidencias.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.all(8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_evidencias[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 8),
            
            OutlinedButton.icon(
              onPressed: _adicionarEvidencia,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Adicionar Foto'),
            ),
            
            const Spacer(),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _enviarDenuncia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enviar Denúncia'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarEvidencia() {
    // Simular seleção de foto
    SnackBarUtils.mostrarInfo(context, 'Funcionalidade de foto será implementada');
  }

  void _enviarDenuncia() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(denunciaProvider.notifier).criarDenuncia(
        aluguelId: widget.aluguelId,
        denuncianteId: 'usuario_atual_id', // Pegar do auth
        denunciadoId: widget.dadosAluguel['locadorId'],
        tipo: _tipoSelecionado,
        descricao: _descricaoController.text.trim(),
        evidencias: _evidencias,
      );

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Denúncia enviada com sucesso! Nossa equipe analisará o caso. 📋',
        );
      }
    } catch (e) {
      SnackBarUtils.mostrarErro(context, 'Erro ao enviar denúncia: $e');
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }
}
