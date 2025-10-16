import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import '../models/contrato_model.dart';
import '../models/denuncia_model.dart';
import '../models/problema_model.dart';
import '../models/verificacao_fotos_model.dart';
import '../models/verificacao_telefone_model.dart';
import '../models/verificacao_residencia_model.dart';
import '../../domain/entities/contrato.dart';
import '../../domain/entities/denuncia.dart';
import '../../domain/entities/problema.dart';
import '../../domain/entities/verificacao_fotos.dart';
import '../../domain/entities/verificacao_telefone.dart';
import '../../domain/entities/verificacao_residencia.dart';
import '../../domain/repositories/seguranca_repository.dart';

/// Implementação do repositório de segurança
/// Segue o padrão de arquitetura limpa e Clean Architecture
class SegurancaRepositoryImpl implements SegurancaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  SegurancaRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ==================== CONTRATOS ====================

  @override
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

      final contrato = ContratoModel(
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
      throw ServerException('Erro ao gerar contrato: ${e.toString()}');
    }
  }

  @override
  Future<void> aceitarContrato(String contratoId) async {
    try {
      // Debug: verificar autenticação
      final currentUser = _auth.currentUser;
      debugPrint('🔐 aceitarContrato: currentUser = ${currentUser?.uid}');

      if (currentUser == null) {
        throw ServerException('Usuário não autenticado');
      }

      const enderecoIp = '192.168.1.1'; // Em produção, obter IP real
      const userAgent = 'Flutter App';
      final assinaturaDigital = _gerarAssinaturaDigital(contratoId, enderecoIp);

      final aceite = AceiteContrato(
        dataHora: DateTime.now(),
        enderecoIp: enderecoIp,
        userAgent: userAgent,
        assinaturaDigital: assinaturaDigital,
      );

      // Debug: verificar dados do contrato antes da atualização
      final contratoDoc = await _firestore.collection('contratos').doc(contratoId).get();
      if (!contratoDoc.exists) {
        throw ServerException('Contrato não encontrado');
      }

      final contratoData = contratoDoc.data();
      debugPrint('📄 aceitarContrato: contratoData = $contratoData');
      debugPrint('👤 aceitarContrato: userId=${currentUser.uid}, locadorId=${contratoData?['locadorId']}, locatarioId=${contratoData?['locatarioId']}');

      await _firestore.collection('contratos').doc(contratoId).update({
        'aceite': aceite.toMap(),
      });

      debugPrint('✅ aceitarContrato: sucesso');
    } catch (e) {
      debugPrint('❌ aceitarContrato: erro = $e');
      throw ServerException('Erro ao aceitar contrato: ${e.toString()}');
    }
  }

  @override
  Future<ContratoDigital?> obterContratoPorAluguel(String aluguelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('contratos')
          .where('aluguelId', isEqualTo: aluguelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ContratoModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw ServerException('Erro ao obter contrato: ${e.toString()}');
    }
  }

  // ==================== VERIFICAÇÃO DE FOTOS ====================

  @override
  Future<VerificacaoFotos> criarVerificacaoFotos({
    required String aluguelId,
    required String itemId,
    required String locatarioId,
    required String locadorId,
  }) async {
    try {
      final verificacaoId = _firestore.collection('verificacoes_fotos').doc().id;

      final verificacao = VerificacaoFotosModel(
        id: verificacaoId,
        aluguelId: aluguelId,
        itemId: itemId,
        locatarioId: locatarioId,
        locadorId: locadorId,
        fotosAntes: [],
        fotosDepois: [],
        verificacaoCompleta: false,
      );

      await _firestore
          .collection('verificacoes_fotos')
          .doc(verificacaoId)
          .set(verificacao.toMap());

      return verificacao;
    } catch (e) {
      throw ServerException('Erro ao criar verificação de fotos: ${e.toString()}');
    }
  }

  @override
  Future<void> adicionarFotosAntes({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  }) async {
    try {
      final urls = await uploadFotosVerificacao(
        fotos: fotos,
        aluguelId: verificacaoId,
        isAntes: true,
      );

      await _firestore.collection('verificacoes_fotos').doc(verificacaoId).update({
        'fotosAntes': urls,
        'dataFotosAntes': FieldValue.serverTimestamp(),
        'observacoesAntes': observacoes,
      });
    } catch (e) {
      throw ServerException('Erro ao adicionar fotos antes: ${e.toString()}');
    }
  }

  @override
  Future<void> adicionarFotosDepois({
    required String verificacaoId,
    required List<File> fotos,
    String? observacoes,
  }) async {
    try {
      final urls = await uploadFotosVerificacao(
        fotos: fotos,
        aluguelId: verificacaoId,
        isAntes: false,
      );

      // Verificar se há fotos "antes" para marcar como completa
      final doc = await _firestore.collection('verificacoes_fotos').doc(verificacaoId).get();
      final fotosAntes = List<String>.from(doc.data()?['fotosAntes'] ?? []);
      final verificacaoCompleta = fotosAntes.isNotEmpty && urls.isNotEmpty;

      await _firestore.collection('verificacoes_fotos').doc(verificacaoId).update({
        'fotosDepois': urls,
        'dataFotosDepois': FieldValue.serverTimestamp(),
        'observacoesDepois': observacoes,
        'verificacaoCompleta': verificacaoCompleta,
      });
    } catch (e) {
      throw ServerException('Erro ao adicionar fotos depois: ${e.toString()}');
    }
  }

  @override
  Future<VerificacaoFotos?> obterVerificacaoFotos(String aluguelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_fotos')
          .where('aluguelId', isEqualTo: aluguelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VerificacaoFotosModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw ServerException('Erro ao obter verificação de fotos: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadFotosVerificacao({
    required List<File> fotos,
    required String aluguelId,
    required bool isAntes,
  }) async {
    try {
      final tipo = isAntes ? 'antes' : 'depois';
      final List<String> urls = [];

      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'verificacao_${aluguelId}_${tipo}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('verificacoes_fotos/$aluguelId/$tipo/$fileName');
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw ServerException('Erro ao fazer upload de fotos: ${e.toString()}');
    }
  }

  // ==================== PROBLEMAS ====================

  @override
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
  }) async {
    try {
      final problemaId = _firestore.collection('problemas').doc().id;

      // Upload de fotos
      final urlsFotos = await uploadFotosProblema(
        fotos: fotos,
        problemaId: problemaId,
      );

      final problema = ProblemaModel(
        id: problemaId,
        aluguelId: aluguelId,
        itemId: itemId,
        reportadoPorId: reportadoPorId,
        reportadoPorNome: reportadoPorNome,
        reportadoContraId: reportadoContraId,
        tipo: tipo,
        prioridade: prioridade,
        descricao: descricao,
        fotos: urlsFotos,
        status: StatusProblema.aberto,
        criadoEm: DateTime.now(),
      );

      await _firestore
          .collection('problemas')
          .doc(problemaId)
          .set(problema.toMap());

      return problema;
    } catch (e) {
      throw ServerException('Erro ao criar problema: ${e.toString()}');
    }
  }

  @override
  Future<List<Problema>> obterProblemasAluguel(String aluguelId) async {
    try {
      final querySnapshot = await _firestore
          .collection('problemas')
          .where('aluguelId', isEqualTo: aluguelId)
          .orderBy('criadoEm', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProblemaModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao obter problemas: ${e.toString()}');
    }
  }

  @override
  Future<void> atualizarStatusProblema({
    required String problemaId,
    required StatusProblema novoStatus,
    String? resolucao,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': novoStatus.name,
      };

      if (novoStatus == StatusProblema.resolvido) {
        updates['resolvidoEm'] = FieldValue.serverTimestamp();
        if (resolucao != null) {
          updates['resolucao'] = resolucao;
        }
      }

      await _firestore.collection('problemas').doc(problemaId).update(updates);
    } catch (e) {
      throw ServerException('Erro ao atualizar status: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadFotosProblema({
    required List<File> fotos,
    required String problemaId,
  }) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'problema_${problemaId}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('problemas/$problemaId/$fileName');
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw ServerException('Erro ao fazer upload de fotos: ${e.toString()}');
    }
  }

  // ==================== DENÚNCIAS ====================

  @override
  Future<Denuncia> criarDenuncia({
    required String aluguelId,
    required String denuncianteId,
    required String denunciadoId,
    required TipoDenuncia tipo,
    required String descricao,
    required List<File> evidencias,
  }) async {
    try {
      final denunciaId = _firestore.collection('denuncias').doc().id;

      // Upload de evidências
      final urlsEvidencias = await uploadEvidencias(
        evidencias: evidencias,
        denunciaId: denunciaId,
      );

      final denuncia = DenunciaModel(
        id: denunciaId,
        aluguelId: aluguelId,
        denuncianteId: denuncianteId,
        denunciadoId: denunciadoId,
        tipo: tipo,
        descricao: descricao,
        evidencias: urlsEvidencias,
        status: StatusDenuncia.pendente,
        criadaEm: DateTime.now(),
      );

      await _firestore
          .collection('denuncias')
          .doc(denunciaId)
          .set(denuncia.toMap());

      return denuncia;
    } catch (e) {
      throw ServerException('Erro ao criar denúncia: ${e.toString()}');
    }
  }

  @override
  Future<List<Denuncia>> obterDenunciasUsuario(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection('denuncias')
          .where('denuncianteId', isEqualTo: usuarioId)
          .orderBy('criadaEm', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DenunciaModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Erro ao obter denúncias: ${e.toString()}');
    }
  }

  @override
  Future<void> atualizarStatusDenuncia({
    required String denunciaId,
    required StatusDenuncia novoStatus,
    String? resolucao,
    String? moderadorId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': novoStatus.name,
      };

      if (novoStatus == StatusDenuncia.resolvida) {
        updates['resolvidaEm'] = FieldValue.serverTimestamp();
        if (resolucao != null) {
          updates['resolucao'] = resolucao;
        }
        if (moderadorId != null) {
          updates['moderadorId'] = moderadorId;
        }
      }

      await _firestore.collection('denuncias').doc(denunciaId).update(updates);
    } catch (e) {
      throw ServerException('Erro ao atualizar status: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadEvidencias({
    required List<File> evidencias,
    required String denunciaId,
  }) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < evidencias.length; i++) {
        final file = evidencias[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'denuncia_${denunciaId}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('denuncias/$denunciaId/$fileName');
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw ServerException('Erro ao fazer upload de evidências: ${e.toString()}');
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

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

  // ==================== MULTAS E ATRASOS ====================

  @override
  Future<double> calcularMultaAtraso({
    required String aluguelId,
    required String locadorId,
    required DateTime dataLimiteDevolucao,
    required double valorDiaria,
  }) async {
    try {
      final agora = DateTime.now();
      
      if (agora.isBefore(dataLimiteDevolucao)) {
        return 0.0; // Não há atraso
      }
      
      final diasAtraso = agora.difference(dataLimiteDevolucao).inDays;
      const multiplicador = 1.5; // 50% de multa sobre o valor da diária
      final multa = diasAtraso * valorDiaria * multiplicador;
      
      // Registrar multa no Firestore
      await _firestore.collection('multas').add({
        'aluguelId': aluguelId,
        'locadorId': locadorId,
        'diasAtraso': diasAtraso,
        'valorDiaria': valorDiaria,
        'multiplicador': multiplicador,
        'valorMulta': multa,
        'calculadaEm': FieldValue.serverTimestamp(),
      });
      
      return multa;
    } catch (e) {
      throw ServerException('Erro ao calcular multa: ${e.toString()}');
    }
  }

  // ==================== STREAMS ====================

  @override
  Stream<List<Problema>> problemasAluguelStream(String aluguelId) {
    return _firestore
        .collection('problemas')
        .where('aluguelId', isEqualTo: aluguelId)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProblemaModel.fromFirestore(doc))
            .toList());
  }

  // ==================== VERIFICAÇÃO DE TELEFONE ====================

  @override
  Future<VerificacaoTelefone> enviarCodigoSMS({
    required String usuarioId,
    required String telefone,
  }) async {
    try {
      final result = await _functions.httpsCallable('enviarCodigoSMS').call({
        'usuarioId': usuarioId,
        'telefone': telefone,
      });

      final data = result.data as Map<String, dynamic>;
      return VerificacaoTelefoneModel.fromEntity(VerificacaoTelefone(
        id: data['id'] as String? ?? '',
        usuarioId: usuarioId,
        telefone: telefone,
        status: StatusVerificacaoTelefone.codigoEnviado,
        dataCriacao: DateTime.now(),
        tentativas: 1,
        verificado: false,
      ));
    } catch (e) {
      throw ServerException('Erro ao enviar código SMS: ${e.toString()}');
    }
  }

  @override
  Future<VerificacaoTelefone> verificarCodigoSMS({
    required String usuarioId,
    required String codigo,
  }) async {
    try {
      final result = await _functions.httpsCallable('verificarCodigoSMS').call({
        'usuarioId': usuarioId,
        'codigo': codigo,
      });

      final data = result.data as Map<String, dynamic>;
      return VerificacaoTelefoneModel.fromEntity(VerificacaoTelefone(
        id: data['id'] as String? ?? '',
        usuarioId: usuarioId,
        telefone: data['telefone'] as String? ?? '',
        status: StatusVerificacaoTelefone.verificado,
        dataCriacao: DateTime.now(),
        tentativas: data['tentativas'] as int? ?? 1,
        verificado: true,
      ));
    } catch (e) {
      throw ServerException('Erro ao verificar código SMS: ${e.toString()}');
    }
  }

  @override
  Future<VerificacaoTelefone?> obterVerificacaoTelefone(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_telefone')
          .where('usuarioId', isEqualTo: usuarioId)
          .orderBy('dataCriacao', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VerificacaoTelefoneModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw ServerException('Erro ao obter verificação de telefone: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelarVerificacaoTelefone(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_telefone')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('verificado', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({
          'status': StatusVerificacaoTelefone.cancelado.name,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ServerException('Erro ao cancelar verificação de telefone: ${e.toString()}');
    }
  }

  // ==================== VERIFICAÇÃO DE RESIDÊNCIA ====================

  @override
  Future<VerificacaoResidencia> solicitarVerificacaoResidencia({
    required String usuarioId,
    required EnderecoVerificacao endereco,
    required File comprovante,
  }) async {
    try {
      // Primeiro faz upload do comprovante
      final comprovanteUrl = await uploadComprovanteResidencia(
        comprovante: comprovante,
        usuarioId: usuarioId,
      );

      final result = await _functions.httpsCallable('solicitarVerificacaoResidencia').call({
        'usuarioId': usuarioId,
        'endereco': endereco.toMap(),
        'comprovanteUrl': comprovanteUrl,
      });

      final data = result.data as Map<String, dynamic>;
      return VerificacaoResidenciaModel.fromEntity(VerificacaoResidencia(
        id: data['id'] as String? ?? '',
        usuarioId: usuarioId,
        endereco: endereco,
        comprovanteUrl: comprovanteUrl,
        status: StatusVerificacaoResidencia.pendente,
        dataCriacao: DateTime.now(),
        aprovado: false,
      ));
    } catch (e) {
      throw ServerException('Erro ao solicitar verificação de residência: ${e.toString()}');
    }
  }

  @override
  Future<VerificacaoResidencia?> obterVerificacaoResidencia(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_residencia')
          .where('usuarioId', isEqualTo: usuarioId)
          .orderBy('dataCriacao', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VerificacaoResidenciaModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw ServerException('Erro ao obter verificação de residência: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadComprovanteResidencia({
    required File comprovante,
    required String usuarioId,
  }) async {
    try {
      final fileName = 'comprovante_residencia_${usuarioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('comprovantes_residencia/$fileName');

      final uploadTask = ref.putFile(comprovante);
      final snapshot = await uploadTask.whenComplete(() => null);

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw ServerException('Erro ao fazer upload do comprovante: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelarVerificacaoResidencia(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection('verificacoes_residencia')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('aprovado', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({
          'status': StatusVerificacaoResidencia.cancelada.name,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ServerException('Erro ao cancelar verificação de residência: ${e.toString()}');
    }
  }
}
