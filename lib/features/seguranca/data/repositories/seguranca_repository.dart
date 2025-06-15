import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../../domain/entities/caucao.dart';
import '../../domain/entities/contrato.dart';
import '../../domain/entities/denuncia.dart';
import '../../domain/entities/verificacao_fotos.dart';

/// Repositório responsável por todas as operações de segurança
class SegurancaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SegurancaRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // ==================== CAUÇÃO ====================

  /// Obtém dados da caução para um aluguel
  Future<Caucao?> obterCaucao(String aluguelId) async {
    try {
      // Simular dados da caução para demonstração
      await Future.delayed(const Duration(seconds: 1));
      
      return Caucao(
        id: 'caucao_$aluguelId',
        aluguelId: aluguelId,
        locatarioId: 'user_123',
        locadorId: 'user_456',
        itemId: 'item_789',
        nomeItem: 'Furadeira Bosch Professional',
        valorCaucao: 100.0,
        valorAluguel: 50.0,
        diasAluguel: 3,
        status: StatusCaucao.pendente,
        dataCriacao: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Erro ao obter caução: $e');
    }
  }

  /// Processa o pagamento da caução
  Future<void> processarCaucao({
    required String aluguelId,
    required String metodoPagamento,
    required double valorCaucao,
  }) async {
    try {
      // Simular processamento do pagamento
      await Future.delayed(const Duration(seconds: 2));
      
      // Aqui seria a integração real com gateway de pagamento
      final transacaoId = 'TXN_${Random().nextInt(999999)}';
      
      // Atualizar status no Firestore
      await _firestore.collection('caucoes').doc('caucao_$aluguelId').set({
        'aluguelId': aluguelId,
        'metodoPagamento': metodoPagamento,
        'valorCaucao': valorCaucao,
        'status': StatusCaucao.bloqueada.toString().split('.').last,
        'transacaoId': transacaoId,
        'processadoEm': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw ServerException('Erro ao processar caução: $e');
    }
  }

  /// Cria uma nova caução e bloqueia o valor
  Future<Caucao> criarCaucao({
    required String aluguelId,
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required double valor,
  }) async {
    try {
      final caucaoId = _firestore.collection('caucoes').doc().id;
      
      // Simular bloqueio do valor (integração com gateway de pagamento)
      final transacaoId = await _bloquearValorCaucao(valor, locatarioId);
      
      final caucao = Caucao(
        id: caucaoId,
        aluguelId: aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        nomeItem: 'Item Exemplo',
        valorCaucao: valor,
        valorAluguel: 0.0,
        diasAluguel: 1,
        status: StatusCaucao.bloqueada,
        dataCriacao: DateTime.now(),
      );

      await _firestore
          .collection('caucoes')
          .doc(caucaoId)
          .set(caucao.toMap());

      return caucao;
    } catch (e) {
      throw ServerException('Erro ao criar caução: $e');
    }
  }

  /// Libera a caução após devolução aprovada
  Future<void> liberarCaucao(String caucaoId, String motivo) async {
    try {
      final caucaoDoc = await _firestore.collection('caucoes').doc(caucaoId).get();
      
      if (!caucaoDoc.exists) {
        throw ServerException('Caução não encontrada');
      }

      await _firestore.collection('caucoes').doc(caucaoId).update({
        'status': StatusCaucao.liberada.toString().split('.').last,
        'dataLiberacao': DateTime.now().toIso8601String(),
        'motivoBloqueio': motivo,
      });
    } catch (e) {
      throw ServerException('Erro ao liberar caução: $e');
    }
  }

  // ==================== CONTRATOS ====================

  /// Gera contrato digital para o aluguel
  Future<ContratoDigital> gerarContrato({
    required String aluguelId,
    required String locatarioId,
    required String locadorId,
    required String itemId,
    required Map<String, dynamic> dadosAluguel,
  }) async {
    try {
      final contratoId = _firestore.collection('contratos').doc().id;
      
      final conteudoHtml = _gerarConteudoContrato(dadosAluguel);
      
      final contrato = ContratoDigital(
        id: contratoId,
        aluguelId: aluguelId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        itemId: itemId,
        conteudoHtml: conteudoHtml,
        criadoEm: DateTime.now(),
        versaoContrato: '1.0',
      );

      await _firestore
          .collection('contratos')
          .doc(contratoId)
          .set(contrato.toMap());

      return contrato;
    } catch (e) {
      throw ServerException('Erro ao gerar contrato: $e');
    }
  }

  /// Registra aceite do contrato
  Future<void> aceitarContrato(String contratoId) async {
    try {
      const enderecoIp = '192.168.1.1';
      const userAgent = 'Flutter App';
      final assinaturaDigital = _gerarAssinaturaDigital(contratoId, enderecoIp);
      
      final aceite = AceiteContrato(
        dataHora: DateTime.now(),
        enderecoIp: enderecoIp,
        userAgent: userAgent,
        assinaturaDigital: assinaturaDigital,
      );

      await _firestore.collection('contratos').doc(contratoId).update({
        'aceite': aceite.toMap(),
      });
    } catch (e) {
      throw ServerException('Erro ao aceitar contrato: $e');
    }
  }

  // ==================== DENÚNCIAS ====================

  /// Cria uma nova denúncia
  Future<Denuncia> criarDenuncia({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao,
    required List<dynamic> evidencias,
  }) async {
    try {
      final denunciaId = _firestore.collection('denuncias').doc().id;
      
      final denuncia = Denuncia(
        id: denunciaId,
        aluguelId: aluguelId,
        denuncianteId: denuncianteId,
        denunciadoId: denunciadoId,
        tipo: tipo,
        descricao: descricao,
        evidencias: [], // Simplificado para demonstração
        status: StatusDenuncia.pendente,
        criadaEm: DateTime.now(),
      );

      await _firestore
          .collection('denuncias')
          .doc(denunciaId)
          .set(denuncia.toMap());

      return denuncia;
    } catch (e) {
      throw ServerException('Erro ao criar denúncia: $e');
    }
  }

  // ==================== VERIFICAÇÃO DE FOTOS ====================

  /// Salva fotos de verificação do item
  Future<VerificacaoFotos> salvarFotosVerificacao({
    required String aluguelId,
    required String itemId,
    List<File>? fotosAntes,
    List<File>? fotosDepois,
    String? observacoesAntes,
    String? observacoesDepois,
  }) async {
    try {
      final verificacaoId = _firestore.collection('verificacoes_fotos').doc().id;
      
      final verificacao = VerificacaoFotos(
        id: verificacaoId,
        aluguelId: aluguelId,
        itemId: itemId,
        fotosAntes: [], // Simplificado para demonstração
        fotosDepois: [],
        dataFotosAntes: fotosAntes != null ? DateTime.now() : null,
        dataFotosDepois: fotosDepois != null ? DateTime.now() : null,
        observacoesAntes: observacoesAntes,
        observacoesDepois: observacoesDepois,
        verificacaoCompleta: false,
      );

      await _firestore
          .collection('verificacoes_fotos')
          .doc(verificacaoId)
          .set(verificacao.toMap());

      return verificacao;
    } catch (e) {
      throw ServerException('Erro ao salvar fotos de verificação: $e');
    }
  }

  // ==================== MULTAS POR ATRASO ====================

  /// Calcula e aplica multa por atraso
  Future<double> calcularMultaAtraso({
    required String aluguelId,
    required DateTime dataLimiteDevolucao,
    required double valorDiaria,
  }) async {
    try {
      final agora = DateTime.now();
      
      if (agora.isBefore(dataLimiteDevolucao)) {
        return 0.0; // Não há atraso
      }
      
      final diasAtraso = agora.difference(dataLimiteDevolucao).inDays;
      final multiplicador = 1.5; // 50% de multa sobre o valor da diária
      final multa = diasAtraso * valorDiaria * multiplicador;
      
      // Registrar multa no Firestore
      await _firestore.collection('multas').add({
        'aluguelId': aluguelId,
        'diasAtraso': diasAtraso,
        'valorDiaria': valorDiaria,
        'multiplicador': multiplicador,
        'valorMulta': multa,
        'calculadaEm': DateTime.now().millisecondsSinceEpoch,
      });
      
      return multa;
    } catch (e) {
      throw ServerException('Erro ao calcular multa: $e');
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Simula bloqueio de valor no gateway de pagamento
  Future<String> _bloquearValorCaucao(double valor, String usuarioId) async {
    // Aqui seria a integração real com Pix/cartão
    // Por enquanto, simular com ID aleatório
    await Future.delayed(const Duration(seconds: 1));
    return 'TXN_${Random().nextInt(999999)}';
  }

  /// Gera conteúdo HTML do contrato
  String _gerarConteudoContrato(Map<String, dynamic> dados) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Contrato de Aluguel - Coisa Rápida</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { text-align: center; margin-bottom: 30px; }
            .clausula { margin-bottom: 15px; }
            .destaque { font-weight: bold; color: #d32f2f; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>CONTRATO DE ALUGUEL</h1>
            <h2>Coisa Rápida</h2>
        </div>
        
        <div class="clausula">
            <h3>1. PARTES</h3>
            <p><strong>Locador:</strong> ${dados['nomeLocador'] ?? 'Locador'}</p>
            <p><strong>Locatário:</strong> ${dados['nomeLocatario'] ?? 'Locatário'}</p>
        </div>
        
        <div class="clausula">
            <h3>2. OBJETO</h3>
            <p><strong>Item:</strong> ${dados['nomeItem'] ?? 'Item'}</p>
            <p><strong>Descrição:</strong> ${dados['descricaoItem'] ?? 'Descrição do item'}</p>
        </div>
        
        <div class="clausula">
            <h3>3. VALORES</h3>
            <p><strong>Valor do Aluguel:</strong> R\$ ${dados['valorAluguel'] ?? '0,00'}</p>
            <p><strong>Caução:</strong> R\$ ${dados['valorCaucao'] ?? '0,00'}</p>
        </div>
        
        <div class="clausula">
            <h3>4. RESPONSABILIDADES</h3>
            <p class="destaque">O locatário se responsabiliza por:</p>
            <ul>
                <li>Devolver o item nas mesmas condições</li>
                <li>Pagar multa de R\$ ${dados['valorDiaria'] ?? '0,00'} × 1.5 por dia de atraso</li>
                <li>Cobrir custos de danos ou perda total</li>
                <li>Usar o item conforme instruções</li>
            </ul>
        </div>
        
        <div class="clausula">
            <h3>5. CAUÇÃO</h3>
            <p>A caução de R\$ ${dados['valorCaucao'] ?? '0,00'} será:</p>
            <ul>
                <li>Liberada após devolução aprovada</li>
                <li>Utilizada para cobrir danos ou multas</li>
                <li>Não transferida ao locador durante o aluguel</li>
            </ul>
        </div>
        
        <p><strong>Data:</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
    </body>
    </html>
    ''';
  }

  /// Gera assinatura digital do aceite
  String _gerarAssinaturaDigital(String contratoId, String ip) {
    final dados = '$contratoId-$ip-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(dados);
    return base64.encode(bytes);
  }
}
