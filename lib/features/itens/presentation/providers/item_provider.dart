import 'dart:io';
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart'
    as auth_user;
import 'package:coisarapida/features/itens/data/models/item_model.dart';
import 'package:coisarapida/features/seguranca/presentation/providers/seguranca_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geocoding/geocoding.dart';

import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../../data/repositories/item_repository_impl.dart';

// Provider para ItemRepository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ItemRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    apiClient: apiClient,
  );
});

// Provider para ItemController
final itemControllerProvider =
    StateNotifierProvider<ItemController, AsyncValue<void>>((ref) {
  return ItemController(ref.watch(itemRepositoryProvider), ref);
});

// Provider para buscar detalhes de um item específico
final detalhesItemProvider =
    FutureProvider.family<Item?, String>((ref, itemId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getDetalhesItem(itemId);
});

class ItemController extends StateNotifier<AsyncValue<void>> {
  final ItemRepository _itemRepository;
  final Ref _ref;

  ItemController(this._itemRepository, this._ref)
      : super(const AsyncValue.data(null));

  String _formatAddress(Endereco endereco) {
    return '${endereco.rua}, ${endereco.numero}, ${endereco.bairro}, ${endereco.cidade}, ${endereco.estado}, ${endereco.cep}, Brasil';
  }

  void _validarItemParaAtualizacao({
    required String nome,
    required String descricao,
    required List<String> fotosPaths,
    required double precoPorDia,
    double? precoPorHora,
    double? precoVenda,
    double? caucao,
    String? regrasUso,
  }) {
    if (nome.trim().isEmpty || nome.trim().length > 100) {
      throw Exception('Nome inválido: deve ter entre 1 e 100 caracteres.');
    }

    final descricaoTrim = descricao.trim();
    final descricaoLen = descricaoTrim.length;

    if (descricaoTrim.isEmpty || descricaoLen > 1000) {
      throw Exception(
          'Descrição inválida (tamanho: $descricaoLen). Deve ter entre 1 e 1000 caracteres.');
    }

    if (fotosPaths.isEmpty) {
      throw Exception('É necessário pelo menos uma foto do item.');
    }
    if (fotosPaths.length > 5) {
      throw Exception('Máximo de 5 fotos permitido.');
    }

    if (precoPorDia < 0) {
      throw Exception('Preço por dia não pode ser negativo.');
    }
    if (precoPorHora != null && precoPorHora < 0) {
      throw Exception('Preço por hora não pode ser negativo.');
    }
    if (precoVenda != null && precoVenda < 0) {
      throw Exception('Preço de venda não pode ser negativo.');
    }
    if (caucao != null && caucao < 0) {
      throw Exception('Caução não pode ser negativa.');
    }

    if (regrasUso != null && regrasUso.length > 1000) {
      throw Exception('Regras de uso muito longas (máx 1000 caracteres).');
    }
  }

  Future<void> publicarItem({
    required String nome,
    required String descricao,
    required String categoria,
    required List<String> fotosPaths,
    required double precoPorDia,
    double? precoVenda,
    required TipoItem tipo,
    required EstadoItem estado,
    double? precoPorHora,
    double? caucao,
    String? regrasUso,
    required bool aprovacaoAutomatica,
    required Endereco localizacao,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUserAsyncValue = _ref.read(usuarioAtualStreamProvider);
      final auth_user.Usuario? currentUser =
          currentUserAsyncValue.asData?.value;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado para publicar item.');
      }

      // Geocodificar endereço se latitude ou longitude não estiverem definidas
      Endereco localizacaoAtualizada = localizacao;
      if (localizacao.latitude == null ||
          localizacao.longitude == null ||
          localizacao.latitude == 0.0 ||
          localizacao.longitude == 0.0) {
        final addressString = _formatAddress(localizacao);
        final locations = await locationFromAddress(addressString);
        if (locations.isNotEmpty) {
          final location = locations.first;
          localizacaoAtualizada = localizacao.copyWith(
            latitude: location.latitude,
            longitude: location.longitude,
          );
        } else {
          throw Exception(
              'Não foi possível geocodificar o endereço: $addressString');
        }
      }

      final itemId = FirebaseFirestore.instance.collection('itens').doc().id;

      List<File> filesToUpload = fotosPaths
          .where((p) => !p.startsWith('http'))
          .map((p) => File(p))
          .toList();
      List<String> existingUrls =
          fotosPaths.where((p) => p.startsWith('http')).toList();

      List<String> uploadedUrls = [];
      if (filesToUpload.isNotEmpty) {
        uploadedUrls = await _itemRepository.uploadFotos(filesToUpload, itemId);
      }

      final allFotoUrls = [...existingUrls, ...uploadedUrls];

      _validarItemParaAtualizacao(
        nome: nome,
        descricao: descricao,
        fotosPaths: allFotoUrls,
        precoPorDia: precoPorDia,
        precoPorHora: precoPorHora,
        precoVenda: precoVenda,
        caucao: caucao,
        regrasUso: regrasUso,
      );

      final item = ItemModel(
        id: itemId,
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        fotos: allFotoUrls,
        precoPorDia: precoPorDia,
        precoVenda: precoVenda,
        tipo: tipo,
        estado: estado,
        precoPorHora: precoPorHora,
        valorCaucao: caucao,
        regrasUso: regrasUso,
        disponivel: true,
        aprovacaoAutomatica: aprovacaoAutomatica,
        proprietarioId: currentUser.id,
        proprietarioNome: currentUser.nome,
        proprietarioReputacao: currentUser.reputacao,
        localizacao: localizacaoAtualizada,
        criadoEm: DateTime.now(),
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

  Future<void> atualizarItem({
    required String itemId,
    required String nome,
    required String descricao,
    required String categoria,
    required List<String> fotosPaths, // Caminhos locais ou URLs existentes
    required double precoPorDia,
    double? precoVenda,
    required TipoItem tipo,
    required EstadoItem estado,
    double? precoPorHora,
    double? caucao,
    String? regrasUso,
    required bool aprovacaoAutomatica,
    required Item itemOriginal,
  }) async {
    state = const AsyncValue.loading();
    try {
      _validarItemParaAtualizacao(
        nome: nome,
        descricao: descricao,
        fotosPaths: fotosPaths,
        precoPorDia: precoPorDia,
        precoPorHora: precoPorHora,
        precoVenda: precoVenda,
        caucao: caucao,
        regrasUso: regrasUso,
      );
      // Geocodificar endereço caso lat/lon estejam ausentes no itemOriginal
      Endereco localizacaoAtualizada = itemOriginal.localizacao;
      if (localizacaoAtualizada.latitude == null ||
          localizacaoAtualizada.longitude == null ||
          localizacaoAtualizada.latitude == 0.0 ||
          localizacaoAtualizada.longitude == 0.0) {
        final addressString = _formatAddress(localizacaoAtualizada);
        final locations = await locationFromAddress(addressString);
        if (locations.isNotEmpty) {
          final location = locations.first;
          localizacaoAtualizada = localizacaoAtualizada.copyWith(
            latitude: location.latitude,
            longitude: location.longitude,
          );
        } else {
          // Se não conseguiu pegar coordenadas, lançar para que regras sejam respeitadas
          throw Exception(
              'Não foi possível geocodificar o endereço do item para atualização.');
        }
      }
      // Processar fotos
      List<String> fotosFinais = [];
      List<String> fotosParaDeletar = [];

      // Identifica fotos que foram removidas
      for (final fotoOriginal in itemOriginal.fotos) {
        if (!fotosPaths.contains(fotoOriginal)) {
          fotosParaDeletar.add(fotoOriginal);
        }
      }

      // Faz upload de novas fotos (que são caminhos locais)
      List<File> novasFotos = [];
      for (final foto in fotosPaths) {
        if (foto.startsWith('http') || foto.startsWith('https')) {
          // É uma foto já existente na nuvem
          fotosFinais.add(foto);
        } else {
          // É uma foto nova (caminho local)
          novasFotos.add(File(foto));
        }
      }

      // Upload das novas fotos
      if (novasFotos.isNotEmpty) {
        final urlsNovasFotos =
            await _itemRepository.uploadFotos(novasFotos, itemId);
        fotosFinais.addAll(urlsNovasFotos);
      }

      // Criar item atualizado
      final itemAtualizado = ItemModel(
        id: itemId,
        proprietarioId: itemOriginal.proprietarioId,
        proprietarioNome: itemOriginal.proprietarioNome,
        proprietarioReputacao: itemOriginal.proprietarioReputacao,
        nome: nome,
        descricao: descricao,
        categoria: categoria,
        fotos: fotosFinais,
        precoPorDia: precoPorDia,
        precoPorHora: precoPorHora,
        precoVenda: precoVenda,
        valorCaucao: caucao,
        regrasUso: regrasUso,
        tipo: tipo,
        estado: estado,
        disponivel: itemOriginal.disponivel,
        aprovacaoAutomatica: aprovacaoAutomatica,
        criadoEm: itemOriginal.criadoEm,
        atualizadoEm: DateTime.now(),
        localizacao: localizacaoAtualizada,
        avaliacao: itemOriginal.avaliacao,
        totalAlugueis: itemOriginal.totalAlugueis,
        visualizacoes: itemOriginal.visualizacoes,
      );

      // Atualizar no Firebase
      await _itemRepository.atualizarItem(itemAtualizado);

      state = const AsyncValue.data(null);

      // Deletar fotos antigas em background (não bloqueia a UI)
      // Fazemos isso DEPOIS de atualizar o state para não atrasar a resposta ao usuário
      if (fotosParaDeletar.isNotEmpty) {
        // Executar em background sem await para não bloquear
        _deletarFotosAntigasEmBackground(fotosParaDeletar);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Deleta fotos antigas em background sem bloquear a UI
  /// Aguarda 5 segundos para garantir que os caches foram atualizados
  Future<void> _deletarFotosAntigasEmBackground(List<String> fotosUrls) async {
    try {
      // Aguarda 5 segundos para garantir propagação dos caches
      await Future.delayed(const Duration(seconds: 5));

      print(
          'Iniciando exclusão de ${fotosUrls.length} fotos antigas do Storage...');
      int sucessos = 0;
      int falhas = 0;

      for (final fotoUrl in fotosUrls) {
        try {
          await _itemRepository.deletarFoto(fotoUrl);
          sucessos++;
          print('✓ Foto deletada: ${fotoUrl.split('/').last.split('?').first}');
        } catch (e) {
          falhas++;
          print('✗ Erro ao deletar foto: $e');
        }
      }

      print('Limpeza concluída: $sucessos sucessos, $falhas falhas');
    } catch (e) {
      print('Erro na limpeza de fotos antigas: $e');
      // Não propagamos o erro pois isso é uma operação em background
    }
  }
}
