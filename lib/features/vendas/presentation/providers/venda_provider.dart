import 'package:coisarapida/features/vendas/data/repositories/venda_repository_impl.dart';
import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:coisarapida/features/vendas/domain/repositories/venda_repository.dart';
import 'package:coisarapida/features/itens/domain/repositories/item_repository.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final vendaRepositoryProvider = Provider<VendaRepository>((ref) {
  return VendaRepositoryImpl();
});

/// Provider para o controller de Vendas.
final vendaControllerProvider =
    StateNotifierProvider<VendaController, AsyncValue<void>>((ref) {
  final vendaRepository = ref.watch(vendaRepositoryProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);
  return VendaController(vendaRepository, itemRepository);
});

class VendaController extends StateNotifier<AsyncValue<void>> {
  final VendaRepository _vendaRepository;
  final ItemRepository _itemRepository;

  VendaController(this._vendaRepository, this._itemRepository)
      : super(const AsyncValue.data(null));

  /// Registra uma nova venda no sistema.
  Future<void> registrarVenda(Venda venda) async {
    state = const AsyncValue.loading();
    try {
      await _vendaRepository.registrarVenda(venda);
      await _itemRepository.desativarItem(venda.itemId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> atualizarStatusPagamento(String vendaId, String status) async {
    try {
      await _vendaRepository.atualizarStatusPagamento(vendaId, status);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
