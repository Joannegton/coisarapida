import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/avaliacao_controller.dart';
import '../providers/avaliacao_providers.dart';

class AvaliacaoPage extends ConsumerStatefulWidget {
  final String avaliadoId;
  final String avaliadoNome;
  final String? avaliadoFoto;
  final String aluguelId;
  final String? itemId;
  final String? itemNome;
  final bool isObrigatoria;
  final String? avaliacaoPendenteId;

  const AvaliacaoPage({
    super.key,
    required this.avaliadoId,
    required this.avaliadoNome,
    this.avaliadoFoto,
    required this.aluguelId,
    this.itemId,
    this.itemNome,
    this.isObrigatoria = false,
    this.avaliacaoPendenteId,
  });

  @override
  ConsumerState<AvaliacaoPage> createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends ConsumerState<AvaliacaoPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  int? _notaSelecionada;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submeterAvaliacao() async {
    if (_notaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Por favor, selecione uma nota de 1 a 5 estrelas')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final avaliacaoController = ref.read(avaliacaoControllerProvider.notifier);
      try {
        await avaliacaoController.criarAvaliacao(
          avaliadoId: widget.avaliadoId,
          aluguelId: widget.aluguelId,
          itemId: widget.itemId,
          nota: _notaSelecionada!.toDouble(),
          comentario: _comentarioController.text.trim().isNotEmpty 
              ? _comentarioController.text.trim() 
              : null,
        );

        // Se for avaliação obrigatória, marcar como concluída
        if (widget.isObrigatoria && widget.avaliacaoPendenteId != null) {
          final service = ref.read(avaliacaoPendenteServiceProvider);
          await service.marcarAvaliacaoConcluida(widget.avaliacaoPendenteId!);
        }

        if (!mounted) return;

        if (widget.isObrigatoria) {
          // Mostrar diálogo de sucesso
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Avaliação Enviada!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Obrigado pela sua participação! Sua opinião é muito importante para nós.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continuar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        } else {
          SnackBarUtils.mostrarSucesso(context, 'Avaliação enviada com sucesso!');
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (!mounted) return;
        SnackBarUtils.mostrarErro(context, 'Erro ao enviar avaliação: ${e.toString()}');
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = _notaSelecionada != null && starNumber <= _notaSelecionada!;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _notaSelecionada = starNumber;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                size: 48,
                color: isSelected ? Colors.amber : Colors.grey[400],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getNotaDescricao() {
    switch (_notaSelecionada) {
      case 1:
        return 'Muito Insatisfeito';
      case 2:
        return 'Insatisfeito';
      case 3:
        return 'Neutro';
      case 4:
        return 'Satisfeito';
      case 5:
        return 'Muito Satisfeito';
      default:
        return 'Selecione uma nota';
    }
  }

  @override
  Widget build(BuildContext context) {
    final avaliacaoState = ref.watch(avaliacaoControllerProvider);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.isObrigatoria) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Você deve completar a avaliação antes de continuar.')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            widget.isObrigatoria ? 'Avaliação Obrigatória' : 'Avaliar Experiência',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: !widget.isObrigatoria,
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner de avaliação obrigatória
                  if (widget.isObrigatoria) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Avaliação Necessária',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete esta avaliação para continuar usando o app',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Card do usuário avaliado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: widget.avaliadoFoto != null && widget.avaliadoFoto!.isNotEmpty
                              ? NetworkImage(widget.avaliadoFoto!)
                              : null,
                          child: widget.avaliadoFoto == null || widget.avaliadoFoto!.isEmpty
                              ? Text(
                                  widget.avaliadoNome[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.avaliadoNome,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.itemNome != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.itemNome!,
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título da avaliação
                  Text(
                    'Como foi sua experiência?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Sistema de estrelas
                  _buildStarRating(),

                  const SizedBox(height: 16),

                  // Descrição da nota
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _getNotaDescricao(),
                        key: ValueKey(_notaSelecionada),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _notaSelecionada != null 
                              ? theme.primaryColor 
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Campo de comentário
                  Text(
                    'Conte mais sobre sua experiência',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _comentarioController,
                    decoration: InputDecoration(
                      hintText: 'Compartilhe detalhes sobre o que você achou... (opcional)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Comentário deve ter no máximo 500 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botão de enviar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: avaliacaoState.isLoading ? null : _submeterAvaliacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isObrigatoria 
                            ? Colors.green 
                            : theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: avaliacaoState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isObrigatoria 
                                      ? 'Enviar e Continuar' 
                                      : 'Enviar Avaliação',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nota sobre privacidade
                  Text(
                    'Sua avaliação será pública e ajudará outros usuários',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
