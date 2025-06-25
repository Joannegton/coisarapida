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

/// Tela de detalhes do item com informações completas
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
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com fotos
          SliverAppBar(
            expandedHeight: 300,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ),
            pinned: true,
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
              loading: () => const FlexibleSpaceBar(background: Center(child: CircularProgressIndicator())),
              error: (error, stack) => FlexibleSpaceBar(background: Center(child: Text('Erro: $error'))),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorito ? Icons.favorite : Icons.favorite_border,
                  color: isFavorito ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  favoritosNotifier.toggleFavorito(widget.itemId);
                  SnackBarUtils.mostrarSucesso(
                    context,
                    isFavorito ? 'Removido dos favoritos' : 'Adicionado aos favoritos',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => SnackBarUtils.mostrarInfo(context, 'Compartilhar em desenvolvimento'),
              ),
            ],
          ),
          
          // Conteúdo
          itemAsyncValue.when(
            data: (item) {
              if (item == null) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Item não encontrado ou removido.'),
                )));
              }
              return SliverToBoxAdapter(
                child: DetalhesItemContentWidget(
                  item: item,
                  onChatPressed: _isCreatingChat ? null : () => _abrirOuCriarChat(item),
                  formatarData: Utils.formatarDataPorExtenso,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))),
            error: (error, stack) => SliverToBoxAdapter(child: Center(child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Erro ao carregar detalhes do item: $error'),
            ))),
          ),
        ],
      ),
      bottomNavigationBar: itemAsyncValue.maybeWhen(
        data: (item) => item != null
            ? DetalhesItemBottomBarWidget(
                item: item,
                isCreatingChat: _isCreatingChat,
                onChatPressed: _isCreatingChat ? null : () => _abrirOuCriarChat(item),
                onAlugarPressed: () => _solicitarAluguel(item),
              )
            : null,
        orElse: () => const SizedBox.shrink(),
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
        SnackBarUtils.mostrarErro(context, "Você precisa estar logado para iniciar uma conversa.");
        return;
      }

      final currentUserId = usuarioAtual.id;
      final proprietarioId = item.proprietarioId;

      if (currentUserId == proprietarioId) {
        SnackBarUtils.mostrarInfo(context, "Você não pode iniciar um chat consigo mesmo.");
        return;
      }

      final chatId = await ref.read(chatControllerProvider.notifier).abrirOuCriarChat(usuarioAtual: usuarioAtual, item: item);

      if (mounted) context.push('${AppRoutes.chat}/$chatId', extra: proprietarioId);
    } catch (e) {
      if (mounted) SnackBarUtils.mostrarErro(context, 'Falha ao iniciar chat: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }

  void _solicitarAluguel(Item item) {
    context.push(AppRoutes.solicitarAluguel, extra: item);
  }
}
