import '../entities/avaliacao.dart';

abstract class AvaliacaoRepository {
  Future<void> criarAvaliacao(Avaliacao avaliacao);

  Future<List<Avaliacao>> getAvaliacoesPorUsuario(String usuarioId, {int limite = 10});

  Future<List<Avaliacao>> getAvaliacoesPorItem(String itemId, {int limite = 10});
  // Adicionar métodos para buscar mais avaliações (paginação) se necessário
}