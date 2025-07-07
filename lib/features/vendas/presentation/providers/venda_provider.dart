import 'package:coisarapida/features/vendas/domain/entities/venda.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implementar o repositório de Vendas
// final vendaRepositoryProvider = Provider<VendaRepository>((ref) {
//   return VendaRepositoryImpl();
// });

/// Provider para o controller de Vendas.
final vendaControllerProvider =
    StateNotifierProvider<VendaController, AsyncValue<void>>((ref) {
  // TODO: Passar o repositório real quando for implementado
  return VendaController(ref);
});

class VendaController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  // TODO: Receber o VendaRepository
  VendaController(this._ref) : super(const AsyncValue.data(null));

  /// Registra uma nova venda no sistema.
  Future<void> registrarVenda(Venda venda) async {
    state = const AsyncValue.loading();
    try {
      // Lógica para salvar a venda no Firestore através do repositório
      // await _vendaRepository.registrarVenda(venda);

      // Simulação de sucesso
      await Future.delayed(const Duration(seconds: 2));
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
