import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart'; // Para pegar dados do item
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aluguelControllerProvider = StateNotifierProvider<AluguelController, AsyncValue<void>>((ref) {
  return AluguelController(ref);
});

class AluguelController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AluguelController(this._ref) : super(const AsyncValue.data(null));

  Future<String?> solicitarAluguel({
    required Item item, // Item que está sendo alugado
    required DateTime dataInicio,
    required DateTime dataFim,
    required double precoTotal,
    String? observacoesLocatario,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Correção: Usar authStateProvider para obter o usuário
      final usuarioAsyncValue = _ref.read(authStateProvider);
      final locatario = usuarioAsyncValue.valueOrNull;

      if (locatario == null) {
        throw Exception('Usuário não autenticado para solicitar aluguel.');
      }

      // Gerar um ID único para o aluguel no cliente ou deixar o Firestore gerar
      final aluguelId = FirebaseFirestore.instance.collection('alugueis').doc().id;

      final novoAluguel = Aluguel(
        id: aluguelId,
        itemId: item.id,
        itemNome: item.nome,
        itemFotoUrl: item.fotos.isNotEmpty ? item.fotos.first : '',
        locadorId: item.proprietarioId,
        locadorNome: item.proprietarioNome, // Assumindo que o item tem o nome do proprietário
        locatarioId: locatario.id,
        locatarioNome: locatario.nome,
        dataInicio: dataInicio,
        dataFim: dataFim,
        precoTotal: precoTotal,
        // caucaoValor: item.caucao, // Se o item tiver um campo de caução
        status: StatusAluguel.solicitado,
        criadoEm: DateTime.now(), // O model converterá para Timestamp
        observacoesLocatario: observacoesLocatario,
      );

      final idCriado = await _ref.read(aluguelRepositoryProvider).solicitarAluguel(novoAluguel);
      state = const AsyncValue.data(null);
      return idCriado;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> atualizarStatusAluguel(String aluguelId, StatusAluguel novoStatus, {String? motivo}) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(aluguelRepositoryProvider).atualizarStatusAluguel(aluguelId, novoStatus, motivo: motivo);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  bool get isLoading => state.isLoading;
}