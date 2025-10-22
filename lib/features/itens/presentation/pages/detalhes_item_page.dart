import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/chat/presentation/controllers/chat_controller.dart';
import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../providers/item_provider.dart';
import '../widgets/detalhes_item_app_bar_content_widget.dart';
import '../widgets/detalhes_item_bottom_bar_widget.dart';
import '../widgets/detalhes_item_content_widget.dart';
import '../../../../core/constants/app_routes.dart';

class DetalhesItemPage extends ConsumerStatefulWidget {
  final String itemId;

  const DetalhesItemPage({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<DetalhesItemPage> createState() => _DetalhesItemPageState();
}

class _DetalhesItemPageState extends ConsumerState<DetalhesItemPage> {
  int _fotoAtual = 0;
  bool _isCreatingChat = false;

  @override
  Widget build(BuildContext context) {
    final favoritosState = ref.watch(favoritosProvider);
    final isFavorito = favoritosState.contains(widget.itemId);
    final favoritosNotifier = ref.watch(favoritosProvider.notifier);
    final itemAsyncValue = ref.watch(detalhesItemProvider(widget.itemId));
    final usuarioAtualAsyncValue = ref.watch(usuarioAtualStreamProvider);
    final theme = Theme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.4; // 40% da altura da tela para as fotos

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.colorScheme.surface,
            expandedHeight: expandedHeight,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: theme.brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: theme.brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            pinned: true,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            flexibleSpace: itemAsyncValue.when(
              data: (item) {
                if (item == null) {
                  return const Center(child: Text('Item não encontrado.'));
                }
                return DetalhesItemAppBarContentWidget(
                  item: item,
                  fotoAtual: _fotoAtual,
                  onPageChanged: (index) {
                    setState(() => _fotoAtual = index);
                  },
                );
              },
              loading: () => const FlexibleSpaceBar(
                  background: Center(child: CircularProgressIndicator())),
              error: (error, stack) => FlexibleSpaceBar(
                  background: Center(child: Text('Erro: $error'))),
            ),
            actions: [
              // Só mostrar favoritos se não for o proprietário do item
              usuarioAtualAsyncValue.when(
                data: (usuarioAtual) => itemAsyncValue.maybeWhen(
                  data: (item) {
                    if (item != null && usuarioAtual?.id != item.proprietarioId) {
                      return IconButton(
                        icon: Icon(
                          isFavorito ? Icons.favorite : Icons.favorite_border,
                          color: isFavorito ? Colors.red : theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          favoritosNotifier.toggleFavorito(widget.itemId);
                          SnackBarUtils.mostrarSucesso(
                            context,
                            isFavorito
                                ? 'Removido dos favoritos'
                                : 'Adicionado aos favoritos',
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              IconButton(
                icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
                onPressed: () => SnackBarUtils.mostrarInfo(
                    context, 'Compartilhar em desenvolvimento'),
              ),
            ],
          ),
          itemAsyncValue.when(
            data: (item) {
              if (item == null) {
                return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Item não encontrado ou removido.'),
                )));
              }
              return SliverToBoxAdapter(
                child: DetalhesItemContentWidget(
                  item: item,
                  onChatPressed: usuarioAtualAsyncValue.maybeWhen(
                    data: (usuarioAtual) =>
                        usuarioAtual?.id != item.proprietarioId && !_isCreatingChat
                            ? () => _abrirOuCriarChat(item)
                            : null,
                    orElse: () => _isCreatingChat ? null : () => _abrirOuCriarChat(item),
                  ),
                  formatarData: Utils.formatarDataPorExtenso,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))),
            error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Erro ao carregar detalhes do item: $error'),
            ))),
          ),
        ],
      ),
      bottomNavigationBar: itemAsyncValue.maybeWhen(
        data: (item) => item != null
            ? usuarioAtualAsyncValue.maybeWhen(
                data: (usuarioAtual) {
                  final isProprietario = usuarioAtual?.id == item.proprietarioId;
                  return isProprietario
                      ? _buildBottomBarProprietario(item, theme)
                      : DetalhesItemBottomBarWidget(
                          item: item,
                          onAlugarPressed: () => context.push(AppRoutes.solicitarAluguel, extra: item),
                          onComprarPressed: () => context.push(AppRoutes.comprarItem, extra: item),
                        );
                },
                orElse: () => DetalhesItemBottomBarWidget(
                    item: item,
                    onAlugarPressed: () => context.push(AppRoutes.solicitarAluguel, extra: item),
                    onComprarPressed: () => context.push(AppRoutes.comprarItem, extra: item),
                  ),
              )
            : null,
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBottomBarProprietario(Item item, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04; // 4% da largura da tela

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/editar-item/${item.id}'),
            icon: const Icon(Icons.edit),
            label: const Text(
              'Editar Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirOuCriarChat(Item item) async {
    if (_isCreatingChat) return;

    setState(() {
      _isCreatingChat = true;
    });

    try {
      final usuarioAtual = ref.read(usuarioAtualStreamProvider).value;

      if (usuarioAtual == null) {
        SnackBarUtils.mostrarErro(
            context, "Você precisa estar logado para iniciar uma conversa.");
        return;
      }

      final currentUserId = usuarioAtual.id;
      final proprietarioId = item.proprietarioId;

      if (currentUserId == proprietarioId) {
        SnackBarUtils.mostrarInfo(
            context, "Você não pode iniciar um chat consigo mesmo.");
        return;
      }

      final chatId = await ref
          .read(chatControllerProvider.notifier)
          .abrirOuCriarChat(usuarioAtual: usuarioAtual, item: item);

      if (mounted)
        context.push('${AppRoutes.chat}/$chatId', extra: proprietarioId);
    } catch (e) {
      if (mounted)
        SnackBarUtils.mostrarErro(
            context, 'Falha ao iniciar chat: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }
}
