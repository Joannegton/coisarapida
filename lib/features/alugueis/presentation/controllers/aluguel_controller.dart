import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/alugueis/domain/entities/aluguel.dart';
import 'package:coisarapida/features/alugueis/domain/entities/caucao_aluguel.dart';
import 'package:coisarapida/features/alugueis/domain/repositories/aluguel_repository.dart';
import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart'; // Para pegar dados do item
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aluguelControllerProvider =
    StateNotifierProvider<AluguelController, AsyncValue<void>>((ref) {
  return AluguelController(ref);
});

class AluguelController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AluguelRepository get _aluguelRepository =>
      _ref.read(aluguelRepositoryProvider);
  AluguelController(this._ref) : super(const AsyncValue.data(null));

  bool get isLoading => state.isLoading;

  // Não utilizado Este método pode ser usado se a solicitação for iniciada diretamente com um Item
  // e não passar pelo fluxo completo de contrato/caução primeiro.
  Future<String?> iniciarSolicitacaoComItem({
    required Item item, // Item que está sendo alugado
    required DateTime dataInicio,
    required DateTime dataFim,
    required double precoTotal,
    String? observacoesLocatario,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Correção: Usar authStateProvider para obter o usuário
      final usuarioAsyncValue = _ref.read(usuarioAtualStreamProvider);
      final locatario = usuarioAsyncValue.valueOrNull;

      if (locatario == null) {
        throw Exception('Usuário não autenticado para solicitar aluguel.');
      }

      // Gerar um ID único para o aluguel no cliente ou deixar o Firestore gerar
      final aluguelId =
          FirebaseFirestore.instance.collection('alugueis').doc().id;

      // Criar o objeto de caução a partir dos dados do item
      final caucaoDoAluguel = CaucaoAluguel(
        valor: item.valorCaucao ?? 0.0,
        status: (item.valorCaucao ?? 0.0) > 0
            ? StatusCaucaoAluguel.pendentePagamento
            : StatusCaucaoAluguel.naoAplicavel,
      );

      final novoAluguel = Aluguel(
        id: aluguelId,
        itemId: item.id,
        itemNome: item.nome,
        itemFotoUrl: item.fotos.isNotEmpty ? item.fotos.first : '',
        locadorId: item.proprietarioId,
        locadorNome: item.proprietarioNome,
        locatarioId: locatario.id,
        locatarioNome: locatario.nome,
        dataInicio: dataInicio,
        dataFim: dataFim,
        precoTotal: precoTotal,
        status: StatusAluguel.solicitado,
        criadoEm: DateTime.now(),
        caucao: caucaoDoAluguel,
        observacoesLocatario: observacoesLocatario,
      );

      final idCriado = await _aluguelRepository.solicitarAluguel(novoAluguel);
      state = const AsyncValue.data(null);
      return idCriado;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Novo método para ser chamado pela CaucaoPage
  Future<String> submeterAluguelCompleto(Aluguel aluguel) async {
    state = const AsyncValue.loading();
    try {
      // O ID do aluguel já deve estar definido no objeto 'aluguel'
      final idCriado = await _aluguelRepository.solicitarAluguel(aluguel);
      state = const AsyncValue.data(null);
      return idCriado;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> atualizarStatusAluguel(
      String aluguelId, StatusAluguel novoStatus,
      {String? motivo}) async {
    state = const AsyncValue.loading();
    try {
      await _aluguelRepository.atualizarStatusAluguel(aluguelId, novoStatus,
          motivo: motivo);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> processarPagamentoCaucaoAluguel({
    required String aluguelId,
    required String metodoPagamento,
    // O transacaoId viria da integração real com o gateway
    required String transacaoId, // Ex: 'TXN_SIMULADA_123'
  }) async {
    state = const AsyncValue.loading();
    try {
      await _aluguelRepository.processarPagamentoCaucaoAluguel(
        aluguelId: aluguelId,
        metodoPagamento: metodoPagamento,
        transacaoId: transacaoId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> liberarCaucaoAluguel(String aluguelId,
      {String? motivoRetencao, double? valorRetido}) async {
    state = const AsyncValue.loading();
    try {
      await _aluguelRepository.liberarCaucaoAluguel(
          aluguelId: aluguelId,
          motivoRetencao: motivoRetencao,
          valorRetido: valorRetido);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
