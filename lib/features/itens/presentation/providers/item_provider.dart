import 'dart:io';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart' as auth_user;
import 'package:coisarapida/features/itens/data/models/item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';

import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../../data/repositories/item_repository_impl.dart';

// Provider para ItemRepository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

// Provider para ItemController
final itemControllerProvider = StateNotifierProvider<ItemController, AsyncValue<void>>((ref) {
  return ItemController(ref.watch(itemRepositoryProvider), ref);
});

// Provider para buscar detalhes de um item específico
final detalhesItemProvider = FutureProvider.family<Item?, String>((ref, itemId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getDetalhesItem(itemId);
});

class ItemController extends StateNotifier<AsyncValue<void>> {
  final ItemRepository _itemRepository;
  final Ref _ref;

  ItemController(this._itemRepository, this._ref) : super(const AsyncValue.data(null));

  Future<void> publicarItem({
    required String nome,
    required String descricao,
    required String categoria,
    required List<String> fotosPaths, // Caminhos locais ou URLs existentes
    required double precoPorDia,
    double? precoPorHora,
    double? caucao,
    String? regrasUso,
    required bool aprovacaoAutomatica,
    // Para Localizacao, obter esses dados de alguma forma
    // através de um seletor de mapa ou entrada de endereço + geocodificação
    required Localizacao localizacao,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUserAsyncValue = _ref.read(usuarioAtualStreamProvider);
      final auth_user.Usuario? currentUser = currentUserAsyncValue.asData?.value;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado para publicar item.');
      }

      final itemId = FirebaseFirestore.instance.collection('itens').doc().id;

      List<File> filesToUpload = fotosPaths.where((p) => !p.startsWith('http')).map((p) => File(p)).toList();
      List<String> existingUrls = fotosPaths.where((p) => p.startsWith('http')).toList();
      
      List<String> uploadedUrls = [];
      if (filesToUpload.isNotEmpty) {
        uploadedUrls = await _itemRepository.uploadFotos(filesToUpload, itemId);
      }
      
      final allFotoUrls = [...existingUrls, ...uploadedUrls];

      final item = ItemModel(
        id: itemId,
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        fotos: allFotoUrls,
        precoPorDia: precoPorDia,
        precoPorHora: precoPorHora,
        caucao: caucao,
        regrasUso: regrasUso,
        disponivel: true, // Novo item é sempre disponível inicialmente
        aprovacaoAutomatica: aprovacaoAutomatica,
        proprietarioId: currentUser.id,
        proprietarioNome: currentUser.nome,
        proprietarioReputacao: currentUser.reputacao,
        localizacao: localizacao, // Certifique-se de que este objeto está preenchido
        criadoEm: DateTime.now(), // Firestore usará FieldValue.serverTimestamp() no toMap
        avaliacao: 0.0,
        totalAlugueis: 0,
        visualizacoes: 0,
      );

      await _itemRepository.publicarItem(item);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}