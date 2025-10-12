import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

// import '../../../seguranca/presentation/providers/seguranca_provider.dart'; // SegurancaRepository ainda é usado para multa e denúncia
import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart'; // Para denunciaProvider e segurancaRepositoryProvider
import '../../../seguranca/presentation/widgets/contador_tempo.dart';
import '../../../seguranca/presentation/widgets/upload_fotos_verificacao.dart';
import '../../../seguranca/domain/entities/denuncia.dart';
import '../../../autenticacao/presentation/providers/auth_provider.dart';
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
  double? _valorMulta;
  
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
        locadorId: widget.dadosAluguel['locadorId'],
        dataLimiteDevolucao: dataLimite,
        valorDiaria: double.parse(widget.dadosAluguel['valorDiaria'].toString()),
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
    final dataLimite = DateTime.parse(widget.dadosAluguel['dataLimiteDevolucao']);
    final agora = DateTime.now();
    final emAtraso = agora.isAfter(dataLimite);
    final usuario = ref.watch(usuarioAtualStreamProvider).value;
    final isLocador = usuario?.id == widget.dadosAluguel['locadorId'];
    final isLocatario = usuario?.id == widget.dadosAluguel['compradorId'] || usuario?.id != widget.dadosAluguel['locadorId'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLocador ? 'Gerenciar Aluguel' : 'Status do Aluguel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              widget.dadosAluguel['nomeItem'],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
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
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: emAtraso ? Colors.red[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: emAtraso ? Colors.red[200]! : Colors.green[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  emAtraso ? Icons.warning_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: emAtraso ? Colors.red[700] : Colors.green[700],
                ),
                const SizedBox(width: 6),
                Text(
                  emAtraso ? 'Em Atraso' : 'Em Dia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: emAtraso ? Colors.red[700] : Colors.green[700],
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de progresso do aluguel
                _buildProgressIndicator(theme, dataLimite),

                const SizedBox(height: 20),

                // Status do item
                _buildStatusCard(theme, emAtraso, isLocador),

                const SizedBox(height: 20),

                // Informações do aluguel
                _buildInformacoesAluguel(theme, isLocador),

                const SizedBox(height: 20),

                // Contador de tempo (só para locatário)
                if (isLocatario) ...[
                  ContadorTempo(
                    dataLimite: dataLimite,
                    onAtraso: () => _verificarAtraso(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Upload de fotos de verificação (só para locatário)
                if (isLocatario) ...[
                  UploadFotosVerificacao(
                    aluguelId: widget.aluguelId,
                    itemId: widget.dadosAluguel['itemId'],
                  ),
                  const SizedBox(height: 20),
                ],

                // Botões de ação
                _buildBotoesAcao(theme, emAtraso, isLocador, isLocatario),

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
    final dataInicio = DateTime.parse(widget.dadosAluguel['dataInicio'] ?? agora.subtract(const Duration(days: 1)).toIso8601String());
    final totalDias = dataLimite.difference(dataInicio).inDays;
    final diasPassados = agora.difference(dataInicio).inDays;
    final progresso = (diasPassados / totalDias).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Progresso do Aluguel',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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

          const SizedBox(height: 12),

          // Informações do progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dia ${diasPassados > 0 ? diasPassados : 0} de $totalDias',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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

          const SizedBox(height: 8),

          // Status do progresso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildStatusCard(ThemeData theme, bool emAtraso, bool isLocador) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(16),
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
              size: 32,
              color: emAtraso ? Colors.red[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),

          // Título do status
          Text(
            emAtraso ? 'ALUGUEL EM ATRASO' : 'ALUGUEL ATIVO',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: emAtraso ? Colors.red[800] : Colors.green[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Badge de multa (se houver)
          if (emAtraso && _valorMulta != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  const Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
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
            const SizedBox(height: 12),
          ],

          // Descrição do status
          Container(
            padding: const EdgeInsets.all(12),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informações do Aluguel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid de informações principais
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Item Alugado',
                  widget.dadosAluguel['nomeItem'],
                  Icons.inventory_2_rounded,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Valor Total',
                  'R\$ ${widget.dadosAluguel['valorAluguel']}',
                  Icons.attach_money_rounded,
                  Colors.green[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Caução',
                  'R\$ ${widget.dadosAluguel['valorCaucao']}',
                  Icons.security_rounded,
                  Colors.orange[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  'Data Limite',
                  _formatarData(DateTime.parse(widget.dadosAluguel['dataLimiteDevolucao'])),
                  Icons.calendar_today_rounded,
                  Colors.blue[600]!,
                ),
              ),
            ],
          ),

          // Informações do locador (sempre visível)
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
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
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Locador',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.dadosAluguel['nomeLocador'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Informações do locatário (só para locador)
          if (isLocador) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
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
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Locatário',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildContatoRow(theme, Icons.person, widget.dadosAluguel['nomeLocatario'] ?? 'João Silva'),
                  const SizedBox(height: 8),
                  _buildContatoRow(theme, Icons.phone, widget.dadosAluguel['telefoneLocatario'] ?? '(11) 99999-9999'),
                  const SizedBox(height: 8),
                  _buildContatoRow(theme, Icons.location_on, widget.dadosAluguel['enderecoLocatario'] ?? 'Rua das Flores, 123'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 6),
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
          const SizedBox(height: 6),
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
    return Row(
      children: [
        Icon(
          icone,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
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

  Widget _buildBotoesAcao(ThemeData theme, bool emAtraso, bool isLocador, bool isLocatario) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16), // Margem inferior para evitar corte
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ações Disponíveis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isLocatario) ...[
            // Seção para locatário
            Text(
              'Como Locatário',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

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
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

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
                const SizedBox(width: 12),
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
    return Container(
      width: double.infinity,
      height: isCompact ? 80 : 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? cor : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : cor,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? cor.withOpacity(0.3) : Colors.transparent,
          padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withOpacity(0.2)
                    : cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icone,
                size: isCompact ? 20 : 24,
                color: isPrimary ? Colors.white : cor,
              ),
            ),
            const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
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
                size: 16,
                color: isPrimary ? Colors.white : cor,
              ),
          ],
        ),
      ),
    );
  }  void _confirmarDevolucao() {
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

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarSucesso(
          context,
          'Devolução aprovada! Caução liberada para o locatário. ✅',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao aprovar devolução: $e');
      }
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
