import 'package:coisarapida/core/utils/verificacao_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';

import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart';
import '../../../seguranca/presentation/widgets/contador_tempo.dart';
import '../../../seguranca/presentation/widgets/upload_fotos_verificacao.dart';
import '../../../seguranca/domain/entities/denuncia.dart';
import '../../../autenticacao/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../itens/presentation/providers/item_provider.dart';
import '../../../avaliacoes/presentation/providers/avaliacao_providers.dart';
import '../providers/aluguel_providers.dart';
import '../../domain/entities/aluguel.dart';
import '../../../../core/constants/app_routes.dart';
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
  StreamSubscription<DocumentSnapshot>? _aluguelSubscription;
  double? _valorMulta;
  late Map<String, dynamic> _dadosAluguelAtuais;
  bool _isCreatingChat = false;
  
  @override
  void initState() {
    super.initState();
    // Inicializar dados com valores padrão para campos que podem estar faltando
    _dadosAluguelAtuais = {
      'dataLimiteDevolucao': widget.dadosAluguel['dataLimiteDevolucao'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'locadorId': widget.dadosAluguel['locadorId'] ?? '',
      'valorDiaria': widget.dadosAluguel['valorDiaria'] ?? 0.0,
      'compradorId': widget.dadosAluguel['compradorId'] ?? '',
      'status': widget.dadosAluguel['status'] ?? 'solicitado',
      'nomeItem': widget.dadosAluguel['nomeItem'] ?? 'Item',
      'itemId': widget.dadosAluguel['itemId'] ?? '',
      'dataInicio': widget.dadosAluguel['dataInicio'] ?? DateTime.now().toIso8601String(),
      'valorAluguel': widget.dadosAluguel['valorAluguel'] ?? 0.0,
      'valorCaucao': widget.dadosAluguel['valorCaucao'] ?? 0.0,
      'nomeLocador': widget.dadosAluguel['nomeLocador'] ?? 'Locador',
      'nomeLocatario': widget.dadosAluguel['nomeLocatario'] ?? 'Locatário',
      'telefoneLocatario': widget.dadosAluguel['telefoneLocatario'] ?? '',
      'enderecoLocatario': widget.dadosAluguel['enderecoLocatario'] ?? '',
      ...widget.dadosAluguel, // Sobrescrever com valores reais se existirem
    };
    _iniciarTimer();
    _iniciarListenerAluguel();
  }

  void _iniciarListenerAluguel() {
    _aluguelSubscription = FirebaseFirestore.instance
        .collection('alugueis')
        .doc(widget.aluguelId)
        .snapshots()
        .listen((snapshot) {
          if (mounted && snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            // Mesclar dados do Firestore com valores padrão
            setState(() {
              _dadosAluguelAtuais = {
                'dataLimiteDevolucao': data['dataLimiteDevolucao'] ?? _dadosAluguelAtuais['dataLimiteDevolucao'],
                'locadorId': data['locadorId'] ?? _dadosAluguelAtuais['locadorId'],
                'valorDiaria': data['valorDiaria'] ?? _dadosAluguelAtuais['valorDiaria'],
                'compradorId': data['compradorId'] ?? _dadosAluguelAtuais['compradorId'],
                'status': data['status'] ?? _dadosAluguelAtuais['status'],
                'nomeItem': data['nomeItem'] ?? _dadosAluguelAtuais['nomeItem'],
                'itemId': data['itemId'] ?? _dadosAluguelAtuais['itemId'],
                'dataInicio': data['dataInicio'] ?? _dadosAluguelAtuais['dataInicio'],
                'valorAluguel': data['valorAluguel'] ?? _dadosAluguelAtuais['valorAluguel'],
                'valorCaucao': data['valorCaucao'] ?? _dadosAluguelAtuais['valorCaucao'],
                'nomeLocador': data['nomeLocador'] ?? _dadosAluguelAtuais['nomeLocador'],
                'nomeLocatario': data['nomeLocatario'] ?? _dadosAluguelAtuais['nomeLocatario'],
                'telefoneLocatario': data['telefoneLocatario'] ?? _dadosAluguelAtuais['telefoneLocatario'],
                'enderecoLocatario': data['enderecoLocatario'] ?? _dadosAluguelAtuais['enderecoLocatario'],
                ...data, // Sobrescrever com valores reais do Firestore
              };
            });
          }
        });
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Verificar se há atraso e calcular multa
      _verificarAtraso();
    });
  }

  void _verificarAtraso() async {
    final dataLimite = _parseDateTime(_dadosAluguelAtuais['dataLimiteDevolucao']);
    final agora = DateTime.now();
    
    if (agora.isAfter(dataLimite)) {
      // Calcular multa por atraso
      final repository = ref.read(segurancaRepositoryProvider);
      final multa = await repository.calcularMultaAtraso(
        aluguelId: widget.aluguelId,
        locadorId: _dadosAluguelAtuais['locadorId'],
        dataLimiteDevolucao: dataLimite,
        valorDiaria: double.parse(_dadosAluguelAtuais['valorDiaria'].toString()),
      );
      
      if (multa > 0 && mounted) {
        setState(() {
          _valorMulta = multa;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataLimite = _parseDateTime(_dadosAluguelAtuais['dataLimiteDevolucao']);
    final agora = DateTime.now();
    final emAtraso = agora.isAfter(dataLimite);
    final usuario = ref.watch(usuarioAtualStreamProvider).value;
    final isLocador = usuario?.id == _dadosAluguelAtuais['locadorId'];
    final isLocatario = usuario?.id == _dadosAluguelAtuais['compradorId'] || usuario?.id != _dadosAluguelAtuais['locadorId'];
    
    // Verificar se o status é "solicitado" (aguardando aprovação)
    final statusAluguel = _dadosAluguelAtuais['status'] as String?;
    final isSolicitado = statusAluguel == 'solicitado';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSolicitado
                  ? (isLocador ? 'Nova Solicitação' : 'Solicitação Enviada')
                  : (isLocador ? 'Gerenciar Aluguel' : 'Status do Aluguel'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              _dadosAluguelAtuais['nomeItem'] as String? ?? 'Item',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: theme.shadowColor,
        actions: [
          // Badge de status
          Container(
            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.04),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSolicitado
                  ? Colors.orange[100]
                  : (emAtraso ? Colors.red[100] : Colors.green[100]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSolicitado
                    ? Colors.orange[200]!
                    : (emAtraso ? Colors.red[200]! : Colors.green[200]!),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSolicitado
                      ? Icons.hourglass_empty_rounded
                      : (emAtraso ? Icons.warning_rounded : Icons.check_circle_rounded),
                  size: MediaQuery.of(context).size.width * 0.04,
                  color: isSolicitado
                      ? Colors.orange[700]
                      : (emAtraso ? Colors.red[700] : Colors.green[700]),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                Text(
                  isSolicitado
                      ? 'Pendente'
                      : (emAtraso ? 'Em Atraso' : 'Em Dia'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSolicitado
                        ? Colors.orange[700]
                        : (emAtraso ? Colors.red[700] : Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea( // Adicionado SafeArea para garantir que o conteúdo não seja cortado
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.width * 0.04,
              MediaQuery.of(context).size.width * 0.08,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Se está solicitado, mostrar card de aguardando aprovação
                if (isSolicitado) ...[
                  _buildAguardandoAprovacaoCard(theme, isLocador),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                ] else ...[
                  // Indicador de progresso do aluguel (só para aluguéis aprovados)
                  _buildProgressIndicator(theme, dataLimite),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                  // Status do item
                  _buildStatusCard(theme, emAtraso, isLocador),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                ],

                // Informações do aluguel (sempre visível)
                _buildInformacoesAluguel(theme, isLocador),

                // Apenas mostrar contador, upload e algumas ações se NÃO estiver solicitado
                if (!isSolicitado) ...[
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05),

                  // Contador de tempo (só para locatário)
                  if (isLocatario) ...[
                    ContadorTempo(
                      dataLimite: dataLimite,
                      onAtraso: () => _verificarAtraso(),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                  ],

                  // Upload de fotos de verificação (só para locatário)
                  if (isLocatario && _dadosAluguelAtuais['itemId'] != null) ...[
                    UploadFotosVerificacao(
                      aluguelId: widget.aluguelId,
                      itemId: _dadosAluguelAtuais['itemId'] as String,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                  ],
                ],

                const SizedBox(height: 20),

                // Botões de ação
                _buildBotoesAcao(theme, emAtraso, isLocador, isLocatario, isSolicitado),

                // Espaço extra para garantir que o último card não seja cortado
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, DateTime dataLimite) {
    final agora = DateTime.now();
    final dataInicio = _parseDateTime(_dadosAluguelAtuais['dataInicio'] ?? agora.subtract(const Duration(days: 1)));
    final totalDias = dataLimite.difference(dataInicio).inDays;
    final diasPassados = agora.difference(dataInicio).inDays;
    final progresso = (diasPassados / totalDias).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: theme.colorScheme.primary,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Progresso do Aluguel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),

          // Barra de progresso
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progresso,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: agora.isAfter(dataLimite)
                        ? [Colors.red[400]!, Colors.red[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          SizedBox(height: screenWidth * 0.03),

          // Informações do progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Dia ${diasPassados > 0 ? diasPassados : 0} de $totalDias',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(progresso * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: agora.isAfter(dataLimite) ? Colors.red[600] : Colors.blue[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.02),

          // Status do progresso
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 6),
            decoration: BoxDecoration(
              color: agora.isAfter(dataLimite)
                  ? Colors.red[50]
                  : progresso > 0.8
                      ? Colors.orange[50]
                      : Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: agora.isAfter(dataLimite)
                    ? Colors.red[200]!
                    : progresso > 0.8
                        ? Colors.orange[200]!
                        : Colors.green[200]!,
              ),
            ),
            child: Text(
              agora.isAfter(dataLimite)
                  ? 'Período expirado'
                  : progresso > 0.8
                      ? 'Próximo do fim'
                      : 'Em andamento',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: agora.isAfter(dataLimite)
                    ? Colors.red[700]
                    : progresso > 0.8
                        ? Colors.orange[700]
                        : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAguardandoAprovacaoCard(ThemeData theme, bool isLocador) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.orange[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone com fundo circular
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange[100],
              border: Border.all(
                color: Colors.orange[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              size: screenWidth * 0.08,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: screenWidth * 0.03),

          // Título do status
          Text(
            isLocador ? 'NOVA SOLICITAÇÃO' : 'AGUARDANDO APROVAÇÃO',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth * 0.03),

          // Descrição do status
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Text(
              isLocador
                  ? 'Você recebeu uma nova solicitação de aluguel! Revise os detalhes e decida se deseja aprovar ou recusar.'
                  : 'Sua solicitação de aluguel foi enviada com sucesso! O locador irá analisar e responderá em breve. Você receberá uma notificação quando houver uma resposta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool emAtraso, bool isLocador) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: emAtraso
              ? [Colors.red[100]!, Colors.red[50]!, Colors.white]
              : [Colors.green[100]!, Colors.green[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emAtraso ? Colors.red[200]! : Colors.green[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (emAtraso ? Colors.red : Colors.green).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone com fundo circular
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emAtraso ? Colors.red[100] : Colors.green[100],
              border: Border.all(
                color: emAtraso ? Colors.red[300]! : Colors.green[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              emAtraso ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: screenWidth * 0.08,
              color: emAtraso ? Colors.red[700] : Colors.green[700],
            ),
          ),
          SizedBox(height: screenWidth * 0.03),

          // Título do status
          Text(
            emAtraso ? 'ALUGUEL EM ATRASO' : 'ALUGUEL ATIVO',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: emAtraso ? Colors.red[800] : Colors.green[800],
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth * 0.02),

          // Badge de multa (se houver)
          if (emAtraso && _valorMulta != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[500],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.045,
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    'Multa: R\$ ${_valorMulta!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
          ],

          // Descrição do status
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (emAtraso ? Colors.red : Colors.green).withOpacity(0.3),
              ),
            ),
            child: Text(
              emAtraso
                  ? (isLocador ? 'O locatário está em atraso. Considere aplicar multa e notificar.' : 'Você está em atraso! Devolva o item o quanto antes para evitar multas adicionais.')
                  : (isLocador ? 'Aluguel em andamento. Monitore a devolução e mantenha contato.' : 'Lembre-se de devolver no prazo combinado para manter sua reputação.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: emAtraso ? Colors.red[700] : Colors.green[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacoesAluguel(ThemeData theme, bool isLocador) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Informações do Aluguel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.05),

          // Grid de informações principais
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Item Alugado',
                  _dadosAluguelAtuais['nomeItem'] as String? ?? 'Item',
                  Icons.inventory_2_rounded,
                  theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Valor Total',
                  'R\$ ${_dadosAluguelAtuais['valorAluguel'] ?? 0}',
                  Icons.attach_money_rounded,
                  Colors.green[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Caução',
                  'R\$ ${_dadosAluguelAtuais['valorCaucao'] ?? 0}',
                  Icons.security_rounded,
                  Colors.orange[600]!,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Data Limite',
                  _formatarData(_parseDateTime(_dadosAluguelAtuais['dataLimiteDevolucao'])),
                  Icons.calendar_today_rounded,
                  Colors.blue[600]!,
                ),
              ),
            ],
          ),

          // Informações do locador (sempre visível)
          SizedBox(height: screenWidth * 0.05),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: screenWidth * 0.045,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Locador',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  _dadosAluguelAtuais['nomeLocador'] as String? ?? 'Locador',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Informações do locatário (só para locador)
          if (isLocador) ...[
            SizedBox(height: screenWidth * 0.04),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: screenWidth * 0.045,
                        color: theme.colorScheme.secondary,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Locatário',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  _buildContatoRow(theme, Icons.person, _dadosAluguelAtuais['nomeLocatario'] ?? 'João Silva'),
                  SizedBox(height: screenWidth * 0.02),
                  _buildContatoRow(theme, Icons.phone, _dadosAluguelAtuais['telefoneLocatario'] ?? '(11) 99999-9999'),
                  SizedBox(height: screenWidth * 0.02),
                  _buildContatoRow(theme, Icons.location_on, _dadosAluguelAtuais['enderecoLocatario'] ?? 'Rua das Flores, 123'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String titulo, String valor, IconData icone, Color cor) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: screenWidth * 0.04, color: cor),
              SizedBox(width: screenWidth * 0.015),
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.015),
          Text(
            valor,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContatoRow(ThemeData theme, IconData icone, String texto) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Icon(
          icone,
          size: screenWidth * 0.04,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotoesAcao(ThemeData theme, bool emAtraso, bool isLocador, bool isLocatario, bool isSolicitado) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  color: theme.colorScheme.primary,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Ações Disponíveis',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.05),

          // Se está solicitado, mostrar ações específicas
          if (isSolicitado) ...[
            if (isLocador) ...[
              // Ações para o locador aprovar/recusar
              Text(
                'Solicitação Pendente',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              
              _buildActionButton(
                theme,
                'Aprovar Solicitação',
                'Aceitar este aluguel',
                Icons.check_circle_rounded,
                Colors.green[600]!,
                _aprovarSolicitacao,
                isPrimary: true,
              ),
              
              SizedBox(height: screenWidth * 0.03),
              
              _buildActionButton(
                theme,
                'Recusar Solicitação',
                'Recusar este aluguel',
                Icons.cancel_rounded,
                Colors.red[600]!,
                _recusarSolicitacao,
              ),
            ] else if (isLocatario) ...[
              // Ações para o locatário enquanto aguarda
              Text(
                'Aguardando Aprovação',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, size: screenWidth * 0.05, color: Colors.orange[700]),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'Sua solicitação foi enviada! O locador analisará e responderá em breve.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: screenWidth * 0.03),
              
              _buildActionButton(
                theme,
                'Cancelar Solicitação',
                'Desistir deste aluguel',
                Icons.close_rounded,
                Colors.red[600]!,
                _cancelarSolicitacao,
              ),
            ],
          ] else if (isLocatario) ...[
            // Seção para locatário
            Text(
              'Como Locatário',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),

            // Botão principal - Confirmar Devolução
            _buildActionButton(
              theme,
              'Confirmar Devolução',
              'Confirme que devolveu o item',
              Icons.check_circle_rounded,
              Colors.green[600]!,
              _confirmarDevolucao,
              isPrimary: true,
            ),

            SizedBox(height: screenWidth * 0.03),

            // Botões secundários em linha
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Reportar Problema',
                    'Denunciar danos ou irregularidades',
                    Icons.report_problem_rounded,
                    Colors.orange[600]!,
                    _abrirDenuncia,
                    isCompact: true,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Conversar',
                    'Falar com o locador',
                    Icons.chat_rounded,
                    theme.colorScheme.primary,
                    _abrirChat,
                    isCompact: true,
                  ),
                ),
              ],
            ),
          ] else if (isLocador) ...[
            // Seção para locador
            Text(
              'Como Locador',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),

            // Botão principal - Aprovar Devolução
            _buildActionButton(
              theme,
              'Aprovar Devolução',
              'Confirmar recebimento do item',
              Icons.check_circle_rounded,
              Colors.green[600]!,
              _aprovarDevolucao,
              isPrimary: true,
            ),

            SizedBox(height: screenWidth * 0.03),

            // Botões secundários em linha
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Rejeitar',
                    'Reportar problemas na devolução',
                    Icons.cancel_rounded,
                    Colors.red[600]!,
                    _rejeitarDevolucao,
                    isCompact: true,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Conversar',
                    'Falar com o locatário',
                    Icons.chat_rounded,
                    theme.colorScheme.primary,
                    _abrirChat,
                    isCompact: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    String titulo,
    String subtitulo,
    IconData icone,
    Color cor,
    VoidCallback onPressed, {
    bool isPrimary = false,
    bool isCompact = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      height: isCompact ? screenWidth * 0.2 : screenWidth * 0.25,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? cor : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : cor,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? cor.withOpacity(0.3) : Colors.transparent,
          padding: EdgeInsets.all(screenWidth * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: cor.withOpacity(0.3), width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withOpacity(0.2)
                    : cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icone,
                size: isCompact ? screenWidth * 0.05 : screenWidth * 0.06,
                color: isPrimary ? Colors.white : cor,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titulo,
                    style: (isCompact
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCompact) ...[
                    SizedBox(height: screenWidth * 0.005),
                    Text(
                      subtitulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPrimary
                            ? Colors.white.withOpacity(0.9)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!isCompact)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: screenWidth * 0.04,
                color: isPrimary ? Colors.white : cor,
              ),
          ],
        ),
      ),
    );
  }

  void _aprovarSolicitacao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Solicitação'),
        content: const Text(
          'Você confirma que deseja aprovar esta solicitação de aluguel? '
          'O locatário será notificado e o aluguel será iniciado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processarAprovacaoSolicitacao();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
  }

  void _recusarSolicitacao() {
    final motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Por favor, informe o motivo da recusa. '
              'O locatário será notificado.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo da recusa',
                border: OutlineInputBorder(),
                hintText: 'Ex: Item não disponível no período',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final motivo = motivoController.text.trim();
              if (motivo.isEmpty) {
                SnackBarUtils.mostrarErro(context, 'Informe o motivo da recusa');
                return;
              }
              Navigator.of(context).pop();
              _processarRecusaSolicitacao(motivo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }

  void _cancelarSolicitacao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitação'),
        content: const Text(
          'Você confirma que deseja cancelar esta solicitação de aluguel? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processarCancelamentoSolicitacao();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _processarAprovacaoSolicitacao() async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aprovando solicitação...'),
            ],
          ),
        ),
      );

      // TODO: Implementar lógica de aprovação no backend
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Solicitação aprovada! O locatário foi notificado. ✅',
        );
        // Voltar para a tela anterior ou recarregar
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao aprovar solicitação: $e');
      }
    }
  }

  void _processarRecusaSolicitacao(String motivo) async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Recusando solicitação...'),
            ],
          ),
        ),
      );

      // TODO: Implementar lógica de recusa no backend
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Solicitação recusada. O locatário foi notificado. ℹ️',
        );
        // Voltar para a tela anterior
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao recusar solicitação: $e');
      }
    }
  }

  void _processarCancelamentoSolicitacao() async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cancelando solicitação...'),
            ],
          ),
        ),
      );

      // TODO: Implementar lógica de cancelamento no backend
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Solicitação cancelada com sucesso. ✅',
        );
        // Voltar para a tela anterior
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao cancelar solicitação: $e');
      }
    }
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
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    bool dialogAberto = false;
    
    try {
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
      dialogAberto = true;

      // Atualizar status do aluguel para "devolucaoPendente"
      final aluguelController = ref.read(aluguelControllerProvider.notifier);
      await aluguelController.atualizarStatusAluguel(
        widget.aluguelId, 
        StatusAluguel.devolucaoPendente,
      );

      if (mounted && dialogAberto) {
        dialogAberto = false;
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Devolução confirmada! Aguarde aprovação do locador. ✅',
        );
      }
    } catch (e) {
      if (mounted && dialogAberto) {
        dialogAberto = false;
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao processar devolução: $e');
      }
    }
  }

  void _aprovarDevolucao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Devolução'),
        content: const Text(
          'Você confirma que o item foi devolvido em perfeitas condições? '
          'Esta ação liberará a caução para o locatário.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processarAprovacao();
            },
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
  }

  void _rejeitarDevolucao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Devolução'),
        content: const Text(
          'Por qual motivo você está rejeitando a devolução? '
          'O locatário será notificado e poderá contestar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processarRejeicao();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  void _processarAprovacao() async {
    // Verificar se o usuário está totalmente verificado
    if (!VerificacaoHelper.usuarioVerificado(ref)) {
      VerificacaoHelper.mostrarDialogVerificacao(context, ref);
      return;
    }

    bool dialogAberto = false;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando aprovação...'),
            ],
          ),
        ),
      );
      dialogAberto = true;

      // Atualizar status do aluguel para concluído
      final aluguelController = ref.read(aluguelControllerProvider.notifier);
      await aluguelController.atualizarStatusAluguel(widget.aluguelId, StatusAluguel.concluido);

      // Liberar a caução
      await aluguelController.liberarCaucaoAluguel(widget.aluguelId);

      // Criar avaliações pendentes
      if (mounted) {
        await _criarAvaliacoesPendentes();
      }

      if (mounted && dialogAberto) {
        dialogAberto = false;
        // Navegar para a página de aluguéis após sucesso
        context.go(AppRoutes.meusAlugueis);
        SnackBarUtils.mostrarSucesso(
          context,
          'Devolução aprovada! Caução liberada para o locatário. ✅',
        );
      }
    } catch (e) {
      if (mounted && dialogAberto) {
        dialogAberto = false;
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao aprovar devolução: $e');
      }
    }
  }

  Future<void> _criarAvaliacoesPendentes() async {
    try {
      final usuarioAtual = ref.read(usuarioAtualStreamProvider).value;
      if (usuarioAtual == null) {
        return;
      }

      // Buscar dados completos do aluguel no Firestore
      final aluguelRepository = ref.read(aluguelRepositoryProvider);
      final aluguel = await aluguelRepository.getAluguelPorId(widget.aluguelId);
      
      if (aluguel == null) {
        return;
      }

      // Buscar fotos dos usuários
      final authController = ref.read(authControllerProvider.notifier);
      final locadorUser = await authController.buscarUsuario(aluguel.locadorId);
      final locatarioUser = await authController.buscarUsuario(aluguel.locatarioId);

      final locadorFoto = locadorUser?.fotoUrl;
      final locatarioFoto = locatarioUser?.fotoUrl;

      // Importar o serviço de avaliações pendentes
      final avaliacaoPendenteService = ref.read(avaliacaoPendenteServiceProvider);

      // Criar avaliação pendente para o locatário avaliar o locador
      await avaliacaoPendenteService.criarAvaliacaoPendente(
        aluguelId: widget.aluguelId,
        itemId: aluguel.itemId,
        itemNome: aluguel.itemNome,
        avaliadorId: aluguel.locatarioId,
        avaliadoId: aluguel.locadorId,
        avaliadoNome: aluguel.locadorNome,
        avaliadoFoto: locadorFoto,
        tipoUsuario: 'locatario',
      );

      // Criar avaliação pendente para o locador avaliar o locatário
      await avaliacaoPendenteService.criarAvaliacaoPendente(
        aluguelId: widget.aluguelId,
        itemId: aluguel.itemId,
        itemNome: aluguel.itemNome,
        avaliadorId: aluguel.locadorId,
        avaliadoId: aluguel.locatarioId,
        avaliadoNome: aluguel.locatarioNome,
        avaliadoFoto: locatarioFoto,
        tipoUsuario: 'locador',
      );

    } catch (e) {
      // Não mostrar erro para o usuário, pois isso é um processo em background
    }
  }

  void _processarRejeicao() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando rejeição...'),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Devolução rejeitada. Locatário será notificado. ⚠️',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao rejeitar devolução: $e');
      }
    }
  }

  void _abrirDenuncia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormularioDenuncia(
        aluguelId: widget.aluguelId,
        dadosAluguel: _dadosAluguelAtuais,
      ),
    );
  }

  Future<void> _abrirChat() async {
    if (_isCreatingChat || !mounted) return;

    setState(() {
      _isCreatingChat = true;
    });

    try {
      // 1. Capturar TODAS as referências síncronas ANTES de qualquer await
      final usuarioAtual = ref.read(usuarioAtualStreamProvider).value;
      final itemId = _dadosAluguelAtuais['itemId'] as String?;
      
      // Validações síncronas
      if (usuarioAtual == null) {
        if (mounted) {
          SnackBarUtils.mostrarErro(
              context, "Você precisa estar logado para iniciar uma conversa.");
        }
        return;
      }

      if (itemId == null) {
        if (mounted) {
          SnackBarUtils.mostrarErro(context, "ID do item não encontrado.");
        }
        return;
      }

      // 2. Capturar o FUTURE do provider antes do await
      final itemFuture = ref.read(detalhesItemProvider(itemId).future);
      final chatController = ref.read(chatControllerProvider.notifier);
      
      // 3. AGORA fazer as operações assíncronas usando as referências capturadas
      final item = await itemFuture;
      
      if (!mounted) return;
      
      if (item == null) {
        SnackBarUtils.mostrarErro(context, "Item não encontrado.");
        return;
      }
      
      // 4. Usar o controller capturado anteriormente
      final chatId = await chatController.abrirOuCriarChat(
        usuarioAtual: usuarioAtual, 
        item: item,
      );

      if (!mounted) return;

      final locadorId = _dadosAluguelAtuais['locadorId'] as String?;
      context.push('${AppRoutes.chat}/$chatId', extra: locadorId);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(
            context, 'Falha ao iniciar chat: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aluguelSubscription?.cancel();
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
      await ref.read(criarDenunciaProvider.notifier).criar(
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
