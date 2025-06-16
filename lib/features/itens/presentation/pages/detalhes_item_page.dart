import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart' as chat_entity; // Alias para evitar conflito
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart' as auth_providers; // Alias para auth_provider
import 'package:coisarapida/features/favoritos/providers/favoritos_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../providers/item_provider.dart'; // Para detalhesItemProvider
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

  @override
  Widget build(BuildContext context) {
    final favoritosNotifier = ref.watch(favoritosProvider.notifier);
    final isFavorito = favoritosNotifier.isFavorito(widget.itemId);
    final itemAsyncValue = ref.watch(detalhesItemProvider(widget.itemId));
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com fotos
          SliverAppBar(
            expandedHeight: 300,
            systemOverlayStyle: SystemUiOverlayStyle(
              // Mantém a cor da status bar transparente
              statusBarColor: Colors.transparent,
              // Ajusta o brilho dos ícones da status bar com base no tema atual
              // Se o tema do app for escuro, os ícones da status bar serão claros, e vice-versa.
              statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
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
                  onChatPressed: () => _abrirOuCriarChat(item),
                  formatarData: _formatarData,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))),
            error: (error, stack) => SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Erro ao carregar detalhes do item: $error'),
            ))),
          ),
        ],
      ),
      bottomNavigationBar: itemAsyncValue.maybeWhen(
        data: (item) => item != null
            ? DetalhesItemBottomBarWidget(
                item: item,
                onChatPressed: () => _abrirOuCriarChat(item),
                onAlugarPressed: () => _solicitarAluguel(item),
              )
            : null,
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _abrirOuCriarChat(Item item) async {
    final authRepository = ref.read(auth_providers.authRepositoryProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      SnackBarUtils.mostrarErro(context, "Você precisa estar logado para iniciar um chat.");
      return;
    }

    final currentUserId = currentUser.uid;
    final proprietarioId = item.proprietarioId;

    // Não permitir chat consigo mesmo
    if (currentUserId == proprietarioId) {
      SnackBarUtils.mostrarInfo(context, "Você não pode iniciar um chat consigo mesmo.");
      return;
    }

    // Gerar ID do chat de forma consistente
    List<String> ids = [currentUserId, proprietarioId];
    ids.sort(); // Garante que o ID seja o mesmo independente de quem inicia
    String chatId = '${ids[0]}_${ids[1]}_${item.id}';

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();

    // Buscar informações do proprietário (locador)
    final proprietarioUser = await authRepository.getUsuario(item.proprietarioId);

    if (!chatSnap.exists) {
      // Criar novo chat
      final novoChat = chat_entity.Chat(
        id: chatId,
        itemId: item.id,
        itemNome: item.nome,
        itemFoto: item.fotos.isNotEmpty ? item.fotos.first : '', // Pega a primeira foto do item
        locadorId: item.proprietarioId,
        locadorNome: proprietarioUser?.nome ?? item.proprietarioNome, // Usa o nome do perfil se disponível
        locadorFoto: proprietarioUser?.fotoUrl ?? '', // Usa a foto do perfil se disponível
        locatarioId: currentUserId,
        locatarioNome: currentUser.displayName ?? 'Usuário Anônimo',
        locatarioFoto: currentUser.photoURL ?? '',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
      final chatDataParaSalvar = novoChat.toMap();
      print("Tentando criar chat com os seguintes dados: $chatDataParaSalvar"); // Log dos dados
      await chatRef.set(chatDataParaSalvar).catchError((error) {
        print("Erro ao criar chat no Firestore (detalhes_item_page): $error"); // Log de erro específico
        SnackBarUtils.mostrarErro(context, "Erro ao iniciar chat. Tente novamente.");
        throw error;
      });
    }
    context.push('${AppRoutes.chat}/$chatId');
  }

  void _solicitarAluguel(Item item) {
    // Navegar para a SolicitarAluguelPage, passando o item como 'extra'
    context.push(AppRoutes.solicitarAluguel, extra: item);
  }

  String _formatarData(DateTime data) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day} ${meses[data.month - 1]} ${data.year}';
  }
}
