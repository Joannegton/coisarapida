import 'package:coisarapida/features/vendas/data/repositories/venda_repository_impl.dart';
import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:coisarapida/features/vendas/domain/repositories/venda_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final vendaRepositoryProvider = Provider<VendaRepository>((ref) {
  return VendaRepositoryImpl();
});

/// Provider para o controller de Vendas.
final vendaControllerProvider =
    StateNotifierProvider<VendaController, AsyncValue<void>>((ref) {
  final repository = ref.watch(vendaRepositoryProvider);
  return VendaController(repository);
});

class VendaController extends StateNotifier<AsyncValue<void>> {
  final VendaRepository _vendaRepository;

  VendaController(this._vendaRepository) : super(const AsyncValue.data(null));

  /// Registra uma nova venda no sistema.
  Future<void> registrarVenda(Venda venda) async {
    state = const AsyncValue.loading();
    try {
      await _vendaRepository.registrarVenda(venda);
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
