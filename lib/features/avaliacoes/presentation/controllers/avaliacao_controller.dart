import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:coisarapida/features/avaliacoes/presentation/providers/avaliacao_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final avaliacaoControllerProvider = StateNotifierProvider<AvaliacaoController, AsyncValue<void>>((ref) {
  return AvaliacaoController(ref);
});

class AvaliacaoController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AvaliacaoController(this._ref) : super(const AsyncValue.data(null));

  Future<void> criarAvaliacao({
    required String avaliadoId,
    required String aluguelId,
    required String? itemId,
    required double nota,
    required String? comentario,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      final avaliacaoId = FirebaseFirestore.instance.collection('avaliacoes').doc().id;

      final novaAvaliacao = Avaliacao(
        id: avaliacaoId,
        avaliadorId: currentUser.uid,
        avaliadorNome: currentUser.displayName ?? 'Usuário Anônimo',
        avaliadorFotoUrl: currentUser.photoURL,
        avaliadoId: avaliadoId,
        tipoAvaliado: TipoAvaliado.usuario, // Avaliando um usuário neste contexto
        aluguelId: aluguelId,
        itemId: itemId, // Associar ao item do chat, se aplicável
        nota: nota.toInt(),
        comentario: comentario,
        data: DateTime.now(), // O model converterá para Timestamp
      );

      await _ref.read(avaliacaoRepositoryProvider).criarAvaliacao(novaAvaliacao);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      print("Erro ao criar avaliação no controller: $e");
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Para que a UI possa tratar o erro também
    }
  }

  bool get isLoading => state.isLoading;
}