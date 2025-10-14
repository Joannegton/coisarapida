import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/avaliacao_repository_impl.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../../domain/services/avaliacao_pendente_service.dart';
import '../../../autenticacao/presentation/providers/auth_provider.dart';

final avaliacaoRepositoryProvider = Provider<AvaliacaoRepository>((ref) {
  return AvaliacaoRepositoryImpl(firestore: FirebaseFirestore.instance);
});

final avaliacaoPendenteServiceProvider = Provider<AvaliacaoPendenteService>((ref) {
  return AvaliacaoPendenteService(firestore: FirebaseFirestore.instance);
});

// Provider para verificar se há avaliações pendentes
final avaliacoesPendentesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(avaliacaoPendenteServiceProvider);
  final userId = ref.watch(idUsuarioAtualProvider);

  if (userId == null) return Stream.value([]);

  return service.getAvaliacoesPendentes(userId);
});