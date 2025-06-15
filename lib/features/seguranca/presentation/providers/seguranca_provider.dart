import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../data/repositories/seguranca_repository.dart';
import '../../domain/entities/caucao.dart';
import '../../domain/entities/contrato.dart';
import '../../domain/entities/denuncia.dart';
import '../../domain/entities/verificacao_fotos.dart';

/// Provider do repositório de segurança
final segurancaRepositoryProvider = Provider<SegurancaRepository>((ref) {
  return SegurancaRepository();
});

/// Provider para gerenciar caução
final caucaoProvider = StateNotifierProvider.family<CaucaoNotifier, AsyncValue<Caucao?>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return CaucaoNotifier(repository, aluguelId);
  },
);

class CaucaoNotifier extends StateNotifier<AsyncValue<Caucao?>> {
  final SegurancaRepository _repository;
  final String _aluguelId;

  CaucaoNotifier(this._repository, this._aluguelId) : super(const AsyncValue.data(null));

  /// Cria e bloqueia caução
  Future<void> criarCaucao({
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required double valor,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final caucao = await _repository.criarCaucao(
        aluguelId: _aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        valor: valor,
      );
      
      state = AsyncValue.data(caucao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Libera caução
  Future<void> liberarCaucao(String caucaoId, String motivo) async {
    try {
      await _repository.liberarCaucao(caucaoId, motivo);
      
      // Atualizar estado local
      if (state.value != null) {
        final caucaoAtualizada = state.value!.copyWith(
          status: StatusCaucao.liberada,
          liberadaEm: DateTime.now(),
          motivoLiberacao: motivo,
        );
        state = AsyncValue.data(caucaoAtualizada);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider para contratos digitais
final contratoProvider = StateNotifierProvider.family<ContratoNotifier, AsyncValue<ContratoDigital?>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return ContratoNotifier(repository, aluguelId);
  },
);

class ContratoNotifier extends StateNotifier<AsyncValue<ContratoDigital?>> {
  final SegurancaRepository _repository;
  final String _aluguelId;

  ContratoNotifier(this._repository, this._aluguelId) : super(const AsyncValue.data(null));

  /// Gera contrato digital
  Future<void> gerarContrato({
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required Map<String, dynamic> dadosAluguel,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final contrato = await _repository.gerarContrato(
        aluguelId: _aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        dadosAluguel: dadosAluguel,
      );
      
      state = AsyncValue.data(contrato);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Aceita contrato
  Future<void> aceitarContrato(String contratoId) async {
    try {
      // Simular obtenção de IP e User Agent
      const enderecoIp = '192.168.1.1';
      const userAgent = 'Flutter App';
      
      await _repository.aceitarContrato(
        contratoId: contratoId,
        enderecoIp: enderecoIp,
        userAgent: userAgent,
      );
      
      // Atualizar estado local
      if (state.value != null) {
        final aceite = AceiteContrato(
          dataHora: DateTime.now(),
          enderecoIp: enderecoIp,
          userAgent: userAgent,
          assinaturaDigital: 'assinatura_digital',
        );
        
        final contratoAtualizado = ContratoDigital(
          id: state.value!.id,
          aluguelId: state.value!.aluguelId,
          locatarioId: state.value!.locatarioId,
          locadorId: state.value!.locadorId,
          itemId: state.value!.itemId,
          conteudoHtml: state.value!.conteudoHtml,
          criadoEm: state.value!.criadoEm,
          aceite: aceite,
          versaoContrato: state.value!.versaoContrato,
        );
        
        state = AsyncValue.data(contratoAtualizado);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider para denúncias
final denunciaProvider = StateNotifierProvider<DenunciaNotifier, AsyncValue<List<Denuncia>>>(
  (ref) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return DenunciaNotifier(repository);
  },
);

class DenunciaNotifier extends StateNotifier<AsyncValue<List<Denuncia>>> {
  final SegurancaRepository _repository;

  DenunciaNotifier(this._repository) : super(const AsyncValue.data([]));

  /// Cria nova denúncia
  Future<void> criarDenuncia({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao,
    required List<File> evidencias,
  }) async {
    try {
      final denuncia = await _repository.criarDenuncia(
        aluguelId: aluguelId,
        denuncianteId: denuncianteId,
        denunciadoId: denunciadoId,
        tipo: tipo,
        descricao: descricao,
        evidencias: evidencias,
      );
      
      // Adicionar à lista local
      final denunciasAtuais = state.value ?? [];
      state = AsyncValue.data([...denunciasAtuais, denuncia]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider para verificação de fotos
final verificacaoFotosProvider = StateNotifierProvider.family<VerificacaoFotosNotifier, AsyncValue<VerificacaoFotos?>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return VerificacaoFotosNotifier(repository, aluguelId);
  },
);

class VerificacaoFotosNotifier extends StateNotifier<AsyncValue<VerificacaoFotos?>> {
  final SegurancaRepository _repository;
  final String _aluguelId;

  VerificacaoFotosNotifier(this._repository, this._aluguelId) : super(const AsyncValue.data(null));

  /// Salva fotos de verificação
  Future<void> salvarFotos({
    required String itemId,
    List<File>? fotosAntes,
    List<File>? fotosDepois,
    String? observacoesAntes,
    String? observacoesDepois,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final verificacao = await _repository.salvarFotosVerificacao(
        aluguelId: _aluguelId,
        itemId: itemId,
        fotosAntes: fotosAntes,
        fotosDepois: fotosDepois,
        observacoesAntes: observacoesAntes,
        observacoesDepois: observacoesDepois,
      );
      
      state = AsyncValue.data(verificacao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
