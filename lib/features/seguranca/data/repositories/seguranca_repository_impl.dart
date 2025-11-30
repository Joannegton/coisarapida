import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/services/api_client.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import '../models/contrato_model.dart';
import '../models/denuncia_model.dart';
import '../models/problema_model.dart';
import '../models/verificacao_fotos_model.dart';
import '../models/verificacao_telefone_model.dart';
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
  final FirebaseAuth _auth;
  final ApiClient apiClient;

  SegurancaRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    required this.apiClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
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

      if (currentUser == null) {
        throw ServerException('Usuário não autenticado');
      }

      // Obter IP e User-Agent reais
      final enderecoIp = await _obterEnderecoIp();
      final userAgent = await _obterUserAgent();
      final assinaturaDigital = _gerarAssinaturaDigital(contratoId, enderecoIp);

      final aceite = AceiteContrato(
        dataHora: DateTime.now(),
        enderecoIp: enderecoIp,
        userAgent: userAgent,
        assinaturaDigital: assinaturaDigital,
      );

      final contratoDoc = await _firestore.collection('contratos').doc(contratoId).get();
      if (!contratoDoc.exists) {
        throw ServerException('Contrato não encontrado');
      }

      final contratoData = contratoDoc.data();

      debugPrint('campos de caeite antes da atualização: ${aceite.toMap()}');
      await _firestore.collection('contratos').doc(contratoId).update({
        if (currentUser.uid == contratoData?['locadorId']) 
          'aceiteLocador': aceite.toMap()
        else if (currentUser.uid == contratoData?['locatarioId'])
          'aceiteLocatario': aceite.toMap(),
      });

    } catch (e) {
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
    final dataHoje = DateTime.now();
    final dataFormatada = "${dataHoje.day}/${dataHoje.month}/${dataHoje.year}";
    
    return '''
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Contrato de Aluguel - Coisa Rápida</title>
          <style>
              body { font-family: Arial, sans-serif; margin: 30px; line-height: 1.6; color: #333; }
              .header { text-align: center; margin-bottom: 30px; }
              h2, h3 { color: #d32f2f; margin-bottom: 5px; }
              h4 { color: #444; margin-bottom: 10px; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
              ul { margin-left: 20px; }
              .destaque { font-weight: bold; color: #d32f2f; }
              .assinaturas { margin-top: 40px; text-align: center; }
              .assinaturas div { display: inline-block; margin: 0 40px; }
              .assinaturas p { margin-top: 5px; border-top: 1px solid #000; padding-top: 5px; }
              .footer { margin-top: 30px; font-size: 12px; color: #666; text-align: center; border-top: 1px solid #ddd; padding-top: 10px; }
              .section { margin-bottom: 20px; }
              .metadata { font-size: 11px; color: #777; margin-top: 5px; }
          </style>
      </head>
      <body>
          <div class="header">
              <h2>CONTRATO DIGITAL DE ALUGUEL DE BENS</h2>
              <h3>Plataforma Coisa Rápida</h3>
              <p>Contrato nº ${dados['contratoId'] ?? 'CR-${DateTime.now().millisecondsSinceEpoch}'}</p>
          </div>

          <div class="section">
              <h4>1. PARTES</h4>
              <p><strong>Locador:</strong> ${dados['nomeLocador'] ?? 'Locador'}</p>
              <p><strong>CPF/CNPJ:</strong> ${dados['documentoLocador'] ?? 'Documento'}</p>
              <p><strong>Locatário:</strong> ${dados['nomeLocatario'] ?? 'Locatário'}</p>
              <p><strong>CPF/CNPJ:</strong> ${dados['documentoLocatario'] ?? 'Documento'}</p>
              <p>Ambas as partes devidamente cadastradas e verificadas na plataforma <strong>Coisa Rápida</strong>, intermediadora deste contrato.</p>
          </div>

          <div class="section">
              <h4>2. OBJETO</h4>
              <p>O presente contrato tem por objeto o aluguel do seguinte item:</p>
              <p><strong>Item:</strong> ${dados['nomeItem'] ?? 'Item'}</p>
              <p><strong>Descrição:</strong> ${dados['descricaoItem'] ?? 'Descrição do item'}</p>
              // ignore: prefer_interpolation_to_compose_strings, prefer_interpolation_to_compose_strings
              <p><strong>Código de identificação:</strong> ${dados['itemId']}</p>
              <p><strong>Condição atual:</strong> ${dados['condicaoItem'] ?? 'Em perfeito estado'}</p>
              <p>O item deverá ser utilizado única e exclusivamente para fins lícitos, respeitando suas condições normais de uso.</p>
          </div>

          <div class="section">
              <h4>3. VALORES E PRAZOS</h4>
              <p><strong>Valor do aluguel:</strong> R\$ ${dados['valorAluguel'] ?? '0,00'}</p>
              <p><strong>Data de início:</strong> ${dados['dataInicio'] ?? dataFormatada}</p>
              <p><strong>Data de término:</strong> ${dados['dataTermino'] ?? 'A definir'}</p>
              <p><strong>Prazo de locação:</strong> ${dados['prazoLocacao'] ?? 'Período acordado entre as partes'}</p>
              <p><strong>Caução:</strong> R\$ ${dados['valorCaucao'] ?? '0,00'}, retida pela plataforma até confirmação da devolução do item.</p>
              <p><strong>Taxa de serviço da plataforma:</strong> R\$ ${dados['taxaPlataforma'] ?? '0,00'}</p>
          </div>

          <div class="section">
              <h4>4. RESPONSABILIDADES DO LOCATÁRIO</h4>
              <ul>
                  <li>Conservar o item em perfeitas condições de uso, sendo responsável por danos, perda total ou furto durante o período de locação;</li>
                  <li>Efetuar a devolução no prazo acordado, sob pena de multa de <strong>1,5x o valor da diária</strong> por dia de atraso;</li>
                  <li>Arcar com custos de reparo ou substituição em caso de danos constatados;</li>
                  <li>Não transferir, emprestar ou sublocar o item a terceiros sem autorização do locador;</li>
                  <li>Utilizar o item de forma adequada, conforme suas instruções e finalidade;</li>
                  <li>Reportar imediatamente à plataforma qualquer incidente, dano ou imprevisto;</li>
                  <li>Fornecer informações verídicas durante todo o processo de aluguel e verificação;</li>
                  <li>Permitir a coleta e rastreamento de dados técnicos, incluindo localização e IP, para fins de segurança.</li>
              </ul>
          </div>

          <div class="section">
              <h4>5. RESPONSABILIDADES DO LOCADOR</h4>
              <ul>
                  <li>Entregar o item em perfeito estado de uso e funcionamento;</li>
                  <li>Fornecer informações claras e precisas sobre o produto e suas condições;</li>
                  <li>Respeitar o valor e o prazo acordados sem cobranças adicionais indevidas;</li>
                  <li>Receber o item e confirmar a devolução via plataforma Coisa Rápida;</li>
                  <li>Fornecer orientações de uso adequado do item, quando necessário;</li>
                  <li>Manter comunicação durante o período de aluguel através dos canais da plataforma;</li>
                  <li>Documentar adequadamente o estado do item antes da entrega através do sistema de verificação fotográfica.</li>
              </ul>
          </div>

          <div class="section">
              <h4>6. INTERMEDIAÇÃO E GARANTIAS DA PLATAFORMA</h4>
              <ul>
                  <li>A Coisa Rápida atua como intermediadora digital, garantindo o bloqueio e liberação segura dos valores;</li>
                  <li>A caução será devolvida integralmente ao locatário após a confirmação de devolução sem danos;</li>
                  <li>Em caso de dano, furto ou não devolução, o valor da caução poderá ser usado total ou parcialmente para indenização do locador;</li>
                  <li>A plataforma poderá reter valores adicionais ou acionar medidas legais em caso de fraude, dano intencional ou reincidência;</li>
                  <li>A plataforma garante a verificação das partes através de sistemas de validação de identidade, análise de histórico e verificação de endereço;</li>
                  <li>Todo o processo de mediação segue as regras disponíveis nos Termos de Uso da plataforma Coisa Rápida.</li>
              </ul>
          </div>

          <div class="section">
              <h4>7. CASOS DE FURTO, PERDA OU DANO TOTAL</h4>
              <p>Em caso de furto, perda ou dano irreparável, o locatário se compromete a:</p>
              <ul>
                  <li>Comunicar imediatamente o fato à plataforma e às autoridades competentes;</li>
                  <li>Indenizar o locador pelo valor integral do item conforme preço de mercado atual ou valor declarado no anúncio;</li>
                  <li>A plataforma poderá intermediar a compensação utilizando a caução e valores adicionais se necessário;</li>
                  <li>Fornecer o Boletim de Ocorrência e documentação necessária para processos de seguro, quando aplicável;</li>
                  <li>Manter-se disponível para esclarecimentos adicionais por até 90 dias após o incidente.</li>
              </ul>
          </div>

          <div class="section">
              <h4>8. DADOS COLETADOS E PRIVACIDADE</h4>
              <p>As partes estão cientes que a plataforma Coisa Rápida coleta e processa os seguintes dados:</p>
              <ul>
                  <li><strong>Dados de identificação:</strong> nome, CPF, documentos oficiais, foto do perfil;</li>
                  <li><strong>Dados técnicos:</strong> endereço IP, localização GPS, modelos de dispositivo, sistema operacional;</li>
                  <li><strong>Dados de transação:</strong> valores, datas, histórico de pagamentos;</li>
                  <li><strong>Dados de verificação:</strong> comprovante de residência, verificação de telefone, validações biométricas;</li>
                  <li><strong>Registros de uso:</strong> logs de acesso, mensagens trocadas através da plataforma, avaliações;</li>
                  <li><strong>Fotos de verificação:</strong> imagens do item no momento da entrega e devolução;</li>
                  <li><strong>Assinaturas digitais:</strong> registros de aceitação de termos e contrato.</li>
              </ul>
              <p>Estes dados são coletados com o propósito de:</p>
              <ul>
                  <li>Garantir a segurança das transações e das partes envolvidas;</li>
                  <li>Validar a identidade dos usuários;</li>
                  <li>Registrar evidências em caso de disputas;</li>
                  <li>Melhorar os serviços da plataforma;</li>
                  <li>Cumprir obrigações legais.</li>
              </ul>
              <p>O tratamento destes dados segue a Política de Privacidade da plataforma e está em conformidade com a Lei Geral de Proteção de Dados (LGPD).</p>
          </div>

          <div class="section">
              <h4>9. ASSINATURA DIGITAL E VALIDAÇÃO</h4>
              <p>Este contrato é assinado digitalmente através da plataforma Coisa Rápida, com os seguintes mecanismos de validação:</p>
              <ul>
                  <li>Autenticação multifator dos usuários;</li>
                  <li>Registro de endereço IP no momento da assinatura (${dados['ipAssinatura'] ?? 'IP do usuário'});</li>
                  <li>Registro de dispositivo utilizado (${dados['dispositivoAssinatura'] ?? 'dispositivo do usuário'});</li>
                  <li>Timestamp criptográfico do momento da aceitação;</li>
                  <li>Armazenamento seguro em blockchain ou sistema equivalente para garantir imutabilidade;</li>
                  <li>Verificação de identidade prévia dos usuários.</li>
              </ul>
              <p>As partes reconhecem que a assinatura digital realizada através da plataforma tem plena validade jurídica, nos termos da MP 2.200-2/2001 e do Art. 10 da Lei 14.063/2020.</p>
          </div>

          <div class="section">
              <h4>10. COMUNICAÇÕES E NOTIFICAÇÕES</h4>
              <p>Todas as comunicações referentes a este contrato devem ser realizadas através dos canais oficiais da plataforma Coisa Rápida:</p>
              <ul>
                  <li>Chat interno da aplicação;</li>
                  <li>Notificações push;</li>
                  <li>E-mails registrados na plataforma;</li>
                  <li>SMS para telefones verificados.</li>
              </ul>
              <p>Comunicações realizadas fora da plataforma não serão consideradas oficiais para fins de mediação de conflitos.</p>
          </div>

          <div class="section">
              <h4>11. RESCISÃO E PENALIDADES</h4>
              <ul>
                  <li>O descumprimento de qualquer cláusula poderá resultar em suspensão da conta e medidas legais cabíveis;</li>
                  <li>As partes concordam em resolver eventuais disputas por mediação via plataforma antes de recorrer ao Judiciário;</li>
                  <li>Cancelamentos antes da retirada do item seguem a política de cancelamento da plataforma;</li>
                  <li>Descumprimentos recorrentes podem levar a penalidades permanentes, incluindo exclusão da plataforma e impossibilidade de novo cadastro.</li>
              </ul>
          </div>

          <div class="section">
              <h4>12. FORO</h4>
              <p>Fica eleito o foro da comarca de ${dados['cidade'] ?? 'São Paulo'} para dirimir quaisquer controvérsias oriundas deste contrato.</p>
          </div>

          <p><strong>Data:</strong> $dataFormatada</p>

          <div class="assinaturas">
              <div>
                  <p>${dados['nomeLocador'] ?? 'Locador'}</p>
              </div>
              <div>
                  <p>${dados['nomeLocatario'] ?? 'Locatário'}</p>
              </div>
          </div>

          <div class="footer">
              <p>Contrato gerado digitalmente pela plataforma Coisa Rápida.</p>
              <p class="metadata">ID do Contrato: ${dados['contratoId'] ?? 'CR-${DateTime.now().millisecondsSinceEpoch}'} | Versão: 1.0 | Gerado em: $dataFormatada</p>
          </div>
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
      
      // Registrar/atualizar multa no Firestore (usar doc por aluguel para evitar duplicação)
      final docRef = _firestore.collection('multas').doc(aluguelId);
      await docRef.set({
        'aluguelId': aluguelId,
        'locadorId': locadorId,
        'diasAtraso': diasAtraso,
        'valorDiaria': valorDiaria,
        'multiplicador': multiplicador,
        'valorMulta': multa,
        'calculadaEm': FieldValue.serverTimestamp(),
        'atualizadaEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
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
  Future<Map<String, dynamic>> enviarCodigoSMS({
    required String telefone,
  }) async {
    try {
      final body = {
        'telefone': telefone,
      };
      await apiClient.post('/seguranca/verificacao-sms/enviar', body: body);

      return {'message': 'Código SMS enviado com sucesso'};
    } catch (e) {
      // Handle errors similar to residence
      final errorMessage = e.toString();
      final regex = RegExp(r'Erro 400:\s*(.+)');
      final match = regex.firstMatch(errorMessage);
      if (match != null) {
        final extractedMessage = match.group(1)!;
        throw ServerException(extractedMessage);
      }
      throw ServerException('Erro ao enviar código SMS: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verificarCodigoSMS({
    required String codigo,
    required String telefone,
  }) async {
    try {
      final body = {
        'telefone': telefone,
        'codigo': codigo,
      };
      await apiClient.post('/seguranca/verificacao-sms/verificar', body: body);

      return { 'message': 'Telefone verificado' };
    } catch (e) {
      final errorMessage = e.toString();
      final regex = RegExp(r'Erro 400:\s*(.+)');
      final match = regex.firstMatch(errorMessage);
      if (match != null) {
        final extractedMessage = match.group(1)!;
        throw ServerException(extractedMessage);
      }
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
  Future<void> solicitarVerificacaoResidencia({
    required String usuarioId,
    String? tipoComprovante,
    String? observacoes,
    required File comprovante,
  }) async {
    try {
      await apiClient.postMultipart(
        '/seguranca/verificacao-residencia',
        fields: {
          'tipoComprovante': tipoComprovante ?? 'mock_front',
          if (observacoes != null) 'observacoes': observacoes,
        },
        files: [comprovante],
        fileFieldName: 'comprovante',
      );
      
      // Atualizar o statusEndereco do usuário para 'em_analise' no Firestore
      await _firestore.collection('usuarios').doc(usuarioId).update({
        'statusEndereco': 'em_analise',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      //TODO ajustar padronização de erros
      // Para erros do apiClient, tentar extrair mensagem do backend
      final errorMessage = e.toString();
      // Procurar por padrão "Erro 400: " seguido da mensagem
      final regex = RegExp(r'Erro 400:\s*(.+)');
      final match = regex.firstMatch(errorMessage);
      if (match != null) {
        final extractedMessage = match.group(1)!;
        throw ServerException(extractedMessage);
      }
      // Fallback para erro genérico
      throw ServerException('Erro ao enviar comprovante');
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

  // ==================== MÉTODOS AUXILIARES ====================

  /// Obtém o endereço IP público do usuário
  Future<String> _obterEnderecoIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      // Fallback para IP local se a API falhar
      return '192.168.1.1';
    } catch (e) {
      debugPrint('Erro ao obter IP: $e');
      return '192.168.1.1';
    }
  }

  /// Obtém informações do dispositivo para construir o User-Agent
  Future<String> _obterUserAgent() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String userAgent = 'Flutter App';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        userAgent = 'Android ${androidInfo.version.release} (${androidInfo.model})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        userAgent = 'iOS ${iosInfo.systemVersion} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        userAgent = 'Windows Flutter App';
      } else if (Platform.isMacOS) {
        userAgent = 'macOS Flutter App';
      } else if (Platform.isLinux) {
        userAgent = 'Linux Flutter App';
      }

      return userAgent;
    } catch (e) {
      debugPrint('Erro ao obter User-Agent: $e');
      return 'Flutter App';
    }
  }
}
