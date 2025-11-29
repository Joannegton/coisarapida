import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:coisarapida/features/itens/presentation/providers/item_provider.dart';

/// Provider que busca os itens do usuário atual
final meusItensProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(usuarioAtualStreamProvider);
  final userId = authState.asData?.value?.id;
  if (userId == null) return [];

  final repository = ref.watch(itemRepositoryProvider);
  final itens = await repository.getItensPorUsuario(userId, limite: 50);

  return itens.map((it) {
    return {
      'id': it.id,
      'nome': it.nome,
      'descricao': it.descricao,
      'categoria': it.categoria,
      'fotos': it.fotos,
      'precoPorDia': it.precoPorDia,
      'precoVenda': it.precoVenda,
      'avaliacao': it.avaliacao,
      'disponivel': it.disponivel,
      'proprietarioNome': it.proprietarioNome,
      'criadoEm': it.criadoEm,
    };
  }).toList();
});
