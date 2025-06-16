import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/avaliacao_repository_impl.dart';
import '../../domain/repositories/avaliacao_repository.dart';

final avaliacaoRepositoryProvider = Provider<AvaliacaoRepository>((ref) {
  return AvaliacaoRepositoryImpl(firestore: FirebaseFirestore.instance);
});