import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/autenticacao/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/aluguel_repository_impl.dart';
import '../../domain/entities/aluguel.dart';
import '../../domain/repositories/aluguel_repository.dart';
import '../controllers/aluguel_controller.dart';

final aluguelRepositoryProvider = Provider<AluguelRepository>((ref) {
  return AluguelRepositoryImpl(firestore: FirebaseFirestore.instance);
});

final aluguelControllerProvider = StateNotifierProvider<AluguelController, AsyncValue<void>>((ref) {
  return AluguelController(ref);
});

final StreamProvider<List<Aluguel>> meusAlugueisProvider = StreamProvider<List<Aluguel>>((ref) {
  // Correção: Usar authStateProvider para obter o usuário
  final usuarioAsyncValue = ref.watch(usuarioAtualStreamProvider);
  final userId = usuarioAsyncValue.whenData((usuario) => usuario?.id).asData?.value;

  if (userId == null) return Stream.value([]);
  return ref.watch(aluguelRepositoryProvider).getAlugueisPorUsuario(userId, comoLocador: true, comoLocatario: true);
});

final solicitacoesRecebidasProvider = StreamProvider<List<Aluguel>>((ref) {
  try {
    final usuarioAsyncValue = ref.watch(usuarioAtualStreamProvider);
    final locadorId = usuarioAsyncValue.whenData((usuario) => usuario?.id).asData?.value;

    if (locadorId == null) {
      return Stream.value([]);
    }

    // Busca apenas onde o usuário é locador
    final repository = ref.watch(aluguelRepositoryProvider);
    return repository.getAlugueisPorUsuario(locadorId, comoLocador: true);
  } catch (e, stackTrace) {
    return Stream.error(e, stackTrace);
  }
});

// Provider para solicitações ENVIADAS pelo usuário (onde ele é locatário)
final solicitacoesEnviadasProvider = StreamProvider<List<Aluguel>>((ref) {
  try {
    final usuarioAsyncValue = ref.watch(usuarioAtualStreamProvider);
    final locatarioId = usuarioAsyncValue.whenData((usuario) => usuario?.id).asData?.value;

    if (locatarioId == null) {
      return Stream.value([]);
    }
    
    // Busca apenas onde o usuário é locatário
    final repository = ref.watch(aluguelRepositoryProvider);
    return repository.getAlugueisPorUsuario(locatarioId, comoLocatario: true);
  } catch (e, stackTrace) {
    return Stream.error(e, stackTrace);
  }
});