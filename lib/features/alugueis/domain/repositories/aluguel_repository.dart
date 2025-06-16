import '../entities/aluguel.dart';

abstract class AluguelRepository {
  Future<String> solicitarAluguel(Aluguel aluguel); // Retorna o ID do aluguel criado

  Future<void> atualizarStatusAluguel(String aluguelId, StatusAluguel novoStatus, {String? motivo});

  Future<Aluguel?> getAluguelPorId(String aluguelId);

  Stream<List<Aluguel>> getAlugueisPorUsuario(String usuarioId, {bool comoLocador = false, bool comoLocatario = false});

  Stream<List<Aluguel>> getSolicitacoesPendentesParaLocador(String locadorId);

  Future<void> processarPagamentoCaucaoAluguel({
    required String aluguelId,
    required String metodoPagamento,
    required String transacaoId,
  });

  Future<void> liberarCaucaoAluguel({
    required String aluguelId,
    String? motivoRetencao,
    double? valorRetido,
  });
}