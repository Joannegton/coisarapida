import 'package:coisarapida/core/constants/app_routes.dart';
import 'package:coisarapida/core/utils/snackbar_utils.dart';
import 'package:coisarapida/features/autenticacao/presentation/widgets/campo_texto_customizado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/avaliacao_controller.dart';
import '../providers/avaliacao_providers.dart';
import '../../../itens/presentation/providers/item_provider.dart';
import '../../../itens/domain/entities/item.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final starSize = screenWidth < 400 ? 36.0 : 40.0;
    final starPadding = screenWidth < 400 ? 2.0 : 4.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starNumber = index + 1;
          final isSelected = _notaSelecionada != null && starNumber <= _notaSelecionada!;

          return Flexible(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _notaSelecionada = starNumber;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: starPadding),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: starSize,
                    color: isSelected ? Colors.amber : Colors.grey[400],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacaoState = ref.watch(avaliacaoControllerProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 20.0;

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
          backgroundColor: theme.colorScheme.primary,
          title: Text('Avaliar Experiência',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            // Conteúdo principal com fade transition
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Banner de avaliação obrigatória
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
                  const SizedBox(height: 20),

                  // Informações do item e usuário
                  Column(
                    children: [
                      // Item: foto + nome lado a lado (se disponível)
                      if (widget.itemId != null) ...[
                        Consumer(
                          builder: (context, ref, child) {
                            final itemAsync = ref.watch(detalhesItemProvider(widget.itemId!));
                            return itemAsync.when(
                              data: (item) {
                                if (item == null) return const SizedBox.shrink();
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[200],
                                      ),
                                      child: item.fotos.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item.fotos.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      color: Colors.grey[300],
                                                    ),
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.grey[300],
                                              ),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.nome,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.tipo == TipoItem.aluguel ? 'Para Alugar' : 'Para Vender',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Carregando item...'),
                                ],
                              ),
                              error: (error, stack) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Usuário: foto + nome lado a lado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: widget.avaliadoFoto != null && widget.avaliadoFoto!.isNotEmpty
                                ? NetworkImage(widget.avaliadoFoto!)
                                : null,
                            child: widget.avaliadoFoto == null || widget.avaliadoFoto!.isEmpty
                                ? Text(
                                    widget.avaliadoNome[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.avaliadoNome,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Título da avaliação

                  // Sistema de estrelas
                  _buildStarRating(),

                  const SizedBox(height: 35),

                  // Campo de comentário
                  Text(
                    'Conte mais sobre sua experiência',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CampoTextoCustomizado(
                    controller: _comentarioController,
                    label: 'Compartilhe detalhes sobre o que você achou...',
                    hint: '(opcional)',
                    maxLines: 5,
                    maxLength: 500,
                    prefixIcon: Icons.message_outlined,
                  ),

                  const SizedBox(height: 35),

                  // Botão de enviar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: avaliacaoState.isLoading ? null : _submeterAvaliacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
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
            // Loading overlay quando está enviando
            if (avaliacaoState.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enviando avaliação...',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
