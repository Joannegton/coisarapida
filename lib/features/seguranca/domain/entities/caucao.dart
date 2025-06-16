import 'package:cloud_firestore/cloud_firestore.dart';

/// Entidade que representa uma caução de aluguel
class Caucao {
  final String id;
  final String aluguelId;
  final String locatarioId;
  final String locadorId;
  final String itemId;
  final String nomeItem;
  final double valorCaucao;
  final double valorAluguel;
  final int diasAluguel;
  final StatusCaucao status;
  final String? metodoPagamento;
  final DateTime dataCriacao;
  final DateTime? dataLiberacao;
  final String? motivoBloqueio;
  final double? valorDescontado;

  const Caucao({
    required this.id,
    required this.aluguelId,
    required this.locatarioId,
    required this.locadorId,
    required this.itemId,
    required this.nomeItem,
    required this.valorCaucao,
    required this.valorAluguel,
    required this.diasAluguel,
    required this.status,
    required this.dataCriacao,
    this.metodoPagamento,
    this.dataLiberacao,
    this.motivoBloqueio,
    this.valorDescontado,
  });

  Caucao copyWith({
    String? id,
    String? aluguelId,
    String? locatarioId,
    String? locadorId,
    String? itemId,
    String? nomeItem,
    double? valorCaucao,
    double? valorAluguel,
    int? diasAluguel,
    StatusCaucao? status,
    String? metodoPagamento,
    DateTime? dataCriacao,
    DateTime? dataLiberacao,
    String? motivoBloqueio,
    double? valorDescontado,
  }) {
    return Caucao(
      id: id ?? this.id,
      aluguelId: aluguelId ?? this.aluguelId,
      locatarioId: locatarioId ?? this.locatarioId,
      locadorId: locadorId ?? this.locadorId,
      itemId: itemId ?? this.itemId,
      nomeItem: nomeItem ?? this.nomeItem,
      valorCaucao: valorCaucao ?? this.valorCaucao,
      valorAluguel: valorAluguel ?? this.valorAluguel,
      diasAluguel: diasAluguel ?? this.diasAluguel,
      status: status ?? this.status,
      metodoPagamento: metodoPagamento ?? this.metodoPagamento,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataLiberacao: dataLiberacao ?? this.dataLiberacao,
      motivoBloqueio: motivoBloqueio ?? this.motivoBloqueio,
      valorDescontado: valorDescontado ?? this.valorDescontado,
    );
  }

  factory Caucao.fromMap(Map<String, dynamic> map) {
    return Caucao(
      id: map['id'] ?? '',
      aluguelId: map['aluguelId'] ?? '',
      locatarioId: map['locatarioId'] ?? '',
      locadorId: map['locadorId'] ?? '',
      itemId: map['itemId'] ?? '',
      nomeItem: map['nomeItem'] ?? '',
      valorCaucao: (map['valorCaucao'] ?? 0.0).toDouble(),
      valorAluguel: (map['valorAluguel'] ?? 0.0).toDouble(),
      diasAluguel: map['diasAluguel'] ?? 0,
      status: StatusCaucao.values.firstWhere(
        (e) => e.toString() == 'StatusCaucao.${map['status']}',
        orElse: () => StatusCaucao.pendente,
      ),
      // Ajuste para ler Timestamp do Firestore
      dataCriacao: map['dataCriacao'] is Timestamp
          ? (map['dataCriacao'] as Timestamp).toDate()
          : DateTime.tryParse(map['dataCriacao']?.toString() ?? '') ?? DateTime.now(), // Fallback
      metodoPagamento: map['metodoPagamento'],
      dataLiberacao: map['dataLiberacao'] != null 
          ? (map['dataLiberacao'] is Timestamp
              ? (map['dataLiberacao'] as Timestamp).toDate()
              : DateTime.tryParse(map['dataLiberacao']?.toString() ?? ''))
          : null,
      motivoBloqueio: map['motivoBloqueio'],
      valorDescontado: map['valorDescontado']?.toDouble(),
    );
  }
  Map<String, dynamic> toMapForCreate() { // Específico para criação
      return {
        'id': id,
        'aluguelId': aluguelId,
        'locatarioId': locatarioId,
        'locadorId': locadorId,
        'itemId': itemId,
        'nomeItem': nomeItem,
        'valorCaucao': valorCaucao,
        'valorAluguel': valorAluguel,
        'diasAluguel': diasAluguel,
        'status': status.toString().split('.').last, // Deve ser 'bloqueada' na criação
        'dataCriacao': FieldValue.serverTimestamp(), // << IMPORTANTE PARA CRIAÇÃO
        'metodoPagamento': metodoPagamento,
        'dataLiberacao': null, // Não existe na criação
        'motivoBloqueio': motivoBloqueio,
        'valorDescontado': valorDescontado,
        // Adicionar campos que podem estar faltando e são definidos no processarCaucao,
        // mas que podem ser nulos ou ter valores padrão na criação inicial.
        'transacaoId': null, 
        'processadoEm': null,
      };
  }
}

/// Status possíveis da caução
enum StatusCaucao {
  pendente,     // Aguardando processamento
  bloqueada,    // Valor bloqueado com sucesso
  liberada,     // Caução liberada após devolução
  utilizada,    // Caução utilizada para cobrir danos/multas
  cancelada,    // Caução cancelada
}
