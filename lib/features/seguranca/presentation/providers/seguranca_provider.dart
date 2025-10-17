import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:io';

import '../../domain/repositories/seguranca_repository.dart';
import '../../data/repositories/seguranca_repository_impl.dart';
import '../../domain/entities/contrato.dart';
import '../../domain/entities/denuncia.dart';
import '../../domain/entities/verificacao_fotos.dart';
import '../../domain/entities/problema.dart';
import '../../domain/entities/verificacao_telefone.dart';
import '../../domain/entities/verificacao_residencia.dart';
import 'package:coisarapida/core/services/api_client.dart';

/// Provider do ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider do repositório de segurança
/// Usa a implementação padronizada seguindo Clean Architecture
final segurancaRepositoryProvider = Provider<SegurancaRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SegurancaRepositoryImpl(apiClient: apiClient);
});

/* /// Provider para gerenciar caução - REMOVIDO
final caucaoProvider = StateNotifierProvider.family<CaucaoNotifier, AsyncValue<Aluguel?>, String>( // Alterado para Aluguel?
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return CaucaoNotifier(repository, aluguelId);
  },
);

class CaucaoNotifier extends StateNotifier<AsyncValue<Caucao?>> {
  final SegurancaRepository _segurancaRepository; // Renomeado para clareza
  final AluguelRepository _aluguelRepository; // Adicionado
  final String _aluguelId;

  CaucaoNotifier(this._segurancaRepository, this._aluguelRepository, this._aluguelId) : super(const AsyncValue.loading()) {
    _carregarCaucao();
  }

  Future<void> _carregarCaucao() async {
    try {
      final caucao = await _repository.obterCaucao(_aluguelId);
      state = AsyncValue.data(caucao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Processa caução
  Future<void> processarCaucao({
    required String metodoPagamento,
    required double valorCaucao,
  }) async {
    try {
      await _aluguelRepository.processarPagamentoCaucaoAluguel( // Chama o método no AluguelRepository
        aluguelId: _aluguelId,
        metodoPagamento: metodoPagamento,
        valorCaucao: valorCaucao,
      );
      await _carregarCaucao();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

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
      rethrow; // Adicionar esta linha para propagar a exceção
    }
  }

  /// Libera caução
  Future<void> liberarCaucao(String caucaoId, String motivo) async {
    try {
      await _aluguelRepository.liberarCaucaoAluguel(aluguelId: _aluguelId, motivoRetencao: motivo); // Chama o método no AluguelRepository
      
      // Atualizar estado local
      if (state.value != null) {
        final caucaoAtualizada = state.value!.copyWith(
          status: StatusCaucao.liberada,
          dataLiberacao: DateTime.now(),
          motivoBloqueio: motivo,
        );
        state = AsyncValue.data(caucaoAtualizada);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
} */

/// Provider para contratos digitais
final contratoProvider = StateNotifierProvider.family<ContratoNotifier,
    AsyncValue<ContratoDigital?>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return ContratoNotifier(repository, aluguelId);
  },
);

class ContratoNotifier extends StateNotifier<AsyncValue<ContratoDigital?>> {
  final SegurancaRepository _repository;
  final String _aluguelId;

  ContratoNotifier(this._repository, this._aluguelId)
      : super(const AsyncValue.data(null));

  /// Carrega contrato existente
  Future<void> carregarContrato() async {
    state = const AsyncValue.loading();

    try {
      final contrato = await _repository.obterContratoPorAluguel(_aluguelId);
      state = AsyncValue.data(contrato);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

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
      rethrow;
    }
  }

  /// Aceita contrato
  Future<void> aceitarContrato(String contratoId) async {
    try {
      await _repository.aceitarContrato(contratoId);

      // TODO Atualizar estado local
      final contrato = state.asData?.value;
      if (contrato != null) {
        final aceite = AceiteContrato(
          dataHora: DateTime.now(),
          enderecoIp: '192.168.1.1',
          userAgent: 'Flutter App',
          assinaturaDigital: 'assinatura_digital',
        );

        final contratoAtualizado = contrato.copyWith(aceite: aceite);
        state = AsyncValue.data(contratoAtualizado);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      debugPrint(
          '[ContratoNotifier] Erro ao aceitar contrato: $e'); // Log opcional
      rethrow;
    }
  }
}

/// Provider para denúncias de um usuário específico
final denunciasUsuarioProvider = StateNotifierProvider.family<
    DenunciasUsuarioNotifier, AsyncValue<List<Denuncia>>, String>(
  (ref, usuarioId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return DenunciasUsuarioNotifier(repository, usuarioId);
  },
);

class DenunciasUsuarioNotifier extends StateNotifier<AsyncValue<List<Denuncia>>> {
  final SegurancaRepository _repository;
  final String _usuarioId;

  DenunciasUsuarioNotifier(this._repository, this._usuarioId)
      : super(const AsyncValue.loading()) {
    _carregarDenuncias();
  }

  /// Carrega denúncias do usuário
  Future<void> _carregarDenuncias() async {
    try {
      final denuncias = await _repository.obterDenunciasUsuario(_usuarioId);
      state = AsyncValue.data(denuncias);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Recarrega as denúncias
  Future<void> recarregar() async {
    state = const AsyncValue.loading();
    await _carregarDenuncias();
  }
}

/// Provider para criar denúncia
final criarDenunciaProvider =
    StateNotifierProvider<CriarDenunciaNotifier, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return CriarDenunciaNotifier(repository);
  },
);

class CriarDenunciaNotifier extends StateNotifier<AsyncValue<void>> {
  final SegurancaRepository _repository;

  CriarDenunciaNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Cria nova denúncia
  Future<Denuncia> criar({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao,
    required List<File> evidencias,
  }) async {
    state = const AsyncValue.loading();

    try {
      final denuncia = await _repository.criarDenuncia(
        aluguelId: aluguelId,
        denuncianteId: denuncianteId,
        denunciadoId: denunciadoId,
        tipo: tipo,
        descricao: descricao,
        evidencias: evidencias,
      );

      state = const AsyncValue.data(null);
      return denuncia;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider para verificação de fotos
final verificacaoFotosProvider = StateNotifierProvider.family<
    VerificacaoFotosNotifier, AsyncValue<VerificacaoFotos?>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return VerificacaoFotosNotifier(repository, aluguelId);
  },
);

class VerificacaoFotosNotifier
    extends StateNotifier<AsyncValue<VerificacaoFotos?>> {
  final SegurancaRepository _repository;
  final String _aluguelId;

  VerificacaoFotosNotifier(this._repository, this._aluguelId)
      : super(const AsyncValue.loading()) {
    _carregarVerificacao();
  }

  /// Carrega verificação existente
  Future<void> _carregarVerificacao() async {
    try {
      final verificacao = await _repository.obterVerificacaoFotos(_aluguelId);
      state = AsyncValue.data(verificacao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Salva fotos de verificação (fotos antes)
  Future<void> salvarFotosAntes({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.adicionarFotosAntes(
        verificacaoId: verificacaoId,
        fotos: fotos,
        observacoes: observacoes,
      );

      // Recarregar verificação atualizada
      await _carregarVerificacao();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Salva fotos de verificação (fotos depois)
  Future<void> salvarFotosDepois({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.adicionarFotosDepois(
        verificacaoId: verificacaoId,
        fotos: fotos,
        observacoes: observacoes,
      );

      // Recarregar verificação atualizada
      await _carregarVerificacao();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Cria uma nova verificação de fotos
  Future<VerificacaoFotos> criarVerificacao({
    required String itemId,
    required String locatarioId,
    required String locadorId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final verificacao = await _repository.criarVerificacaoFotos(
        aluguelId: _aluguelId,
        itemId: itemId,
        locatarioId: locatarioId,
        locadorId: locadorId,
      );

      state = AsyncValue.data(verificacao);
      return verificacao;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Recarrega a verificação
  Future<void> recarregar() async {
    await _carregarVerificacao();
  }
}

// ==================== PROBLEMAS ====================

/// Provider para stream de problemas de um aluguel
final problemasAluguelStreamProvider = StreamProvider.family<List<Problema>, String>(
  (ref, aluguelId) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return repository.problemasAluguelStream(aluguelId);
  },
);

/// Provider para reportar problema
final reportarProblemaProvider = StateNotifierProvider<ReportarProblemaNotifier, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return ReportarProblemaNotifier(repository);
  },
);

class ReportarProblemaNotifier extends StateNotifier<AsyncValue<void>> {
  final SegurancaRepository _repository;

  ReportarProblemaNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Reporta um novo problema
  Future<Problema> reportar({
    required String aluguelId,
    required String itemId,
    required String reportadoPorId,
    required String reportadoPorNome,
    required String reportadoContraId,
    required TipoProblema tipo,
    required PrioridadeProblema prioridade,
    required String descricao,
    List<File>? fotos,
  }) async {
    state = const AsyncValue.loading();

    try {
      final problema = await _repository.criarProblema(
        aluguelId: aluguelId,
        itemId: itemId,
        reportadoPorId: reportadoPorId,
        reportadoPorNome: reportadoPorNome,
        reportadoContraId: reportadoContraId,
        tipo: tipo,
        prioridade: prioridade,
        descricao: descricao,
        fotos: fotos ?? [],
      );

      state = const AsyncValue.data(null);
      return problema;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Atualiza status de um problema
  Future<void> atualizarStatus({
    required String problemaId,
    required StatusProblema novoStatus,
    String? resolucao,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.atualizarStatusProblema(
        problemaId: problemaId,
        novoStatus: novoStatus,
        resolucao: resolucao,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ==================== VERIFICAÇÃO DE TELEFONE ====================

/// Provider para verificação de telefone
final verificacaoTelefoneProvider = StateNotifierProvider<VerificacaoTelefoneNotifier, AsyncValue<Object?>>(
  (ref) {
    final repository = ref.watch(segurancaRepositoryProvider);
    return VerificacaoTelefoneNotifier(repository);
  },
);

class VerificacaoTelefoneNotifier extends StateNotifier<AsyncValue<Object?>> {
  final SegurancaRepository _repository;

  VerificacaoTelefoneNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Envia código SMS para verificação
  Future<void> enviarCodigoSMS({
    required String telefone,
  }) async {
    state = const AsyncValue.loading();

    try {
      final verificacao = await _repository.enviarCodigoSMS(
        telefone: telefone,
      );

      state = AsyncValue.data(verificacao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Verifica código SMS
  Future<void> verificarCodigoSMS({
    required String usuarioId,
    required String codigo,
    required String telefone,
  }) async {
    state = const AsyncValue.loading();

    try {
      final verificacao = await _repository.verificarCodigoSMS(
        codigo: codigo,
        telefone: telefone
      );

      state = AsyncValue.data(verificacao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega verificação atual do usuário
  Future<void> carregarVerificacaoAtual(String usuarioId) async {
    state = const AsyncValue.loading();

    try {
      final verificacao = await _repository.obterVerificacaoTelefone(usuarioId);
      state = AsyncValue.data(verificacao);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cancela verificação em andamento
  Future<void> cancelarVerificacao(String usuarioId) async {
    try {
      await _repository.cancelarVerificacaoTelefone(usuarioId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// ==================== VERIFICAÇÃO DE RESIDÊNCIA ====================

/// Provider para verificação de residência
final verificacaoResidenciaProvider = StateNotifierProvider<VerificacaoResidenciaNotifier, AsyncValue<VerificacaoResidencia?>>(
  (ref) => VerificacaoResidenciaNotifier(ref.watch(segurancaRepositoryProvider)),
);

class VerificacaoResidenciaNotifier extends StateNotifier<AsyncValue<VerificacaoResidencia?>> {
  final SegurancaRepository _repository;

  VerificacaoResidenciaNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Solicita verificação de residência
  Future<void> solicitarVerificacao({
    required String usuarioId,
    required File comprovante,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.solicitarVerificacaoResidencia(
        usuarioId: usuarioId,
        comprovante: comprovante,
      );
      
      // Sucesso - manter estado como data(null) ou definir uma flag de sucesso
      state = AsyncValue.data(null); // Indica que a solicitação foi bem-sucedida
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Faz upload do comprovante
  Future<String> uploadComprovante({
    required File comprovante,
    required String usuarioId,
  }) async {
    try {
      return await _repository.uploadComprovanteResidencia(
        comprovante: comprovante,
        usuarioId: usuarioId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cancela verificação em andamento
  Future<void> cancelarVerificacao(String usuarioId) async {
    try {
      await _repository.cancelarVerificacaoResidencia(usuarioId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
