import 'dart:io';
import '../entities/contrato.dart';
import '../entities/denuncia.dart';
import '../entities/problema.dart';
import '../entities/verificacao_fotos.dart';
import '../entities/verificacao_telefone.dart';
import '../entities/verificacao_residencia.dart';

/// Interface abstrata do repositório de segurança
/// Define os contratos que a implementação deve seguir
abstract class SegurancaRepository {
  // ==================== CONTRATOS ====================
  
  /// Gera um novo contrato digital para o aluguel
  Future<ContratoDigital> gerarContrato({
    required String aluguelId,
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required Map<String, dynamic> dadosAluguel,
  });

  /// Registra o aceite do contrato pelo usuário
  Future<void> aceitarContrato(String contratoId);

  /// Busca um contrato pelo ID do aluguel
  Future<ContratoDigital?> obterContratoPorAluguel(String aluguelId);

  // ==================== VERIFICAÇÃO DE FOTOS ====================
  
  /// Cria uma nova verificação de fotos para um aluguel
  Future<VerificacaoFotos> criarVerificacaoFotos({
    required String aluguelId,
    required String itemId,
    required String locatarioId,
    required String locadorId,
  });

  /// Adiciona fotos do estado inicial do item
  Future<void> adicionarFotosAntes({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  });

  /// Adiciona fotos do estado final do item
  Future<void> adicionarFotosDepois({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  });

  /// Busca a verificação de fotos de um aluguel
  Future<VerificacaoFotos?> obterVerificacaoFotos(String aluguelId);

  /// Faz upload de fotos para o Storage
  Future<List<String>> uploadFotosVerificacao({
    required List<File> fotos,
    required String aluguelId,
    required bool isAntes,
  });

  // ==================== PROBLEMAS ====================
  
  /// Cria um novo problema/report
  Future<Problema> criarProblema({
    required String aluguelId,
    required String itemId,
    required String reportadoPorId,
    required String reportadoPorNome,
    required String reportadoContraId,
    required TipoProblema tipo,
    required PrioridadeProblema prioridade,
    required String descricao,
    required List<File> fotos,
  });

  /// Busca problemas de um aluguel específico
  Future<List<Problema>> obterProblemasAluguel(String aluguelId);

  /// Atualiza o status de um problema
  Future<void> atualizarStatusProblema({
    required String problemaId,
    required StatusProblema novoStatus,
    String? resolucao,
  });

  /// Faz upload de fotos de problemas
  Future<List<String>> uploadFotosProblema({
    required List<File> fotos,
    required String problemaId,
  });

  // ==================== DENÚNCIAS ====================
  
  /// Cria uma nova denúncia
  Future<Denuncia> criarDenuncia({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao,
    required List<File> evidencias,
  });

  /// Busca denúncias de um usuário
  Future<List<Denuncia>> obterDenunciasUsuario(String usuarioId);

  /// Atualiza o status de uma denúncia
  Future<void> atualizarStatusDenuncia({
    required String denunciaId,
    required StatusDenuncia novoStatus,
    String? resolucao,
    String? moderadorId,
  });

  /// Faz upload de evidências de denúncias
  Future<List<String>> uploadEvidencias({
    required List<File> evidencias,
    required String denunciaId,
  });

  // ==================== VERIFICAÇÃO DE TELEFONE ====================

  /// Inicia o processo de verificação de telefone enviando SMS
  Future<VerificacaoTelefone> enviarCodigoSMS({
    required String usuarioId,
    required String telefone,
  });

  /// Verifica o código SMS enviado
  Future<VerificacaoTelefone> verificarCodigoSMS({
    required String usuarioId,
    required String codigo,
  });

  /// Busca a verificação de telefone atual do usuário
  Future<VerificacaoTelefone?> obterVerificacaoTelefone(String usuarioId);

  /// Cancela uma verificação de telefone em andamento
  Future<void> cancelarVerificacaoTelefone(String usuarioId);

  // ==================== VERIFICAÇÃO DE RESIDÊNCIA ====================

  /// Solicita verificação de residência
  Future<VerificacaoResidencia> solicitarVerificacaoResidencia({
    required String usuarioId,
    required EnderecoVerificacao endereco,
    required File comprovante,
  });

  /// Busca a verificação de residência do usuário
  Future<VerificacaoResidencia?> obterVerificacaoResidencia(String usuarioId);

  /// Faz upload do comprovante de residência
  Future<String> uploadComprovanteResidencia({
    required File comprovante,
    required String usuarioId,
  });

  /// Cancela uma solicitação de verificação de residência
  Future<void> cancelarVerificacaoResidencia(String usuarioId);

  // ==================== MULTAS E ATRASOS ====================

  /// Calcula multa por atraso na devolução
  Future<double> calcularMultaAtraso({
    required String aluguelId,
    required String locadorId,
    required DateTime dataLimiteDevolucao,
    required double valorDiaria,
  });

  // ==================== STREAMS ====================

  /// Stream de problemas de um aluguel em tempo real
  Stream<List<Problema>> problemasAluguelStream(String aluguelId);
}
