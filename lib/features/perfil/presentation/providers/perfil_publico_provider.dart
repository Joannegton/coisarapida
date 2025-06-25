import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart'; // Para authRepositoryProvider
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart'; // Para itemRepositoryProvider
import 'package:coisarapida/features/avaliacoes/domain/entities/avaliacao.dart';
import 'package:coisarapida/features/avaliacoes/data/repositories/avaliacao_repository_impl.dart'; // Import direto para o provider
import 'package:coisarapida/features/avaliacoes/domain/repositories/avaliacao_repository.dart';

/// Provider para o repositório de avaliações
final avaliacaoRepositoryProvider = Provider<AvaliacaoRepository>((ref) {
  return AvaliacaoRepositoryImpl();
});

/// Provider para dados do perfil público de um usuário, incluindo itens e avaliações
final perfilPublicoDetalhadoProvider = FutureProvider.family<PerfilPublicoDetalhado, String>((ref, usuarioId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);
  final avaliacaoRepository = ref.watch(avaliacaoRepositoryProvider);

  final usuario = await authRepository.getUsuario(usuarioId);
  if (usuario == null) {
    throw Exception('Usuário não encontrado');
  }

  // Buscar itens e avaliações em paralelo
  final futureItens = itemRepository.getItensPorUsuario(usuarioId, limite: 6);
  final futureAvaliacoes = avaliacaoRepository.getAvaliacoesPorUsuario(usuarioId, limite: 5);

  final resultados = await Future.wait([futureItens, futureAvaliacoes]);
  
  final itens = resultados[0] as List<Item>;
  final avaliacoes = resultados[1] as List<Avaliacao>;

  return PerfilPublicoDetalhado(
    usuario: usuario,
    itensAnunciados: itens,
    avaliacoesRecebidas: avaliacoes,
  );
});

// Provider para os dados detalhados do usuário logado
final meuPerfilProviderApagar = FutureProvider<Usuario>((ref) async {
  final authState = ref.watch(usuarioAtualStreamProvider);
  final userId = authState.asData?.value?.id;

  if (userId == null) {
    throw Exception('Usuário não autenticado.');
  }

  final authRepository = ref.watch(authRepositoryProvider);
  final usuario = await authRepository.getUsuario(userId);

  if (usuario == null) {
    throw Exception('Dados do perfil não encontrados para o usuário logado.');
  }
  return usuario;
});

/// Provider para dados do perfil público de um usuário
// Este provider pode ser mantido se você precisar apenas dos dados básicos do usuário em algum lugar.
// Ou pode ser removido se `perfilPublicoDetalhadoProvider` suprir todas as necessidades.
final perfilPublicoProvider = FutureProvider.family<Usuario?, String>((ref, usuarioId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUsuario(usuarioId);
});

// Nova classe para agrupar dados do perfil público
class PerfilPublicoDetalhado {
  final Usuario usuario;
  final List<Item> itensAnunciados;
  final List<Avaliacao> avaliacoesRecebidas;

  PerfilPublicoDetalhado({
    required this.usuario,
    required this.itensAnunciados,
    required this.avaliacoesRecebidas,
  });
}
