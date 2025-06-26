import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusAluguel {
  solicitado,       
  aprovado,         
  recusado,       
  pagamentoPendente,
  confirmado,     
  emAndamento,   
  devolucaoPendente,
  concluido,        
  cancelado,        
  disputa,          
}

enum StatusAluguelCaucao {
  pendentePagamento, // Aguardando pagamento/bloqueio da caução
  bloqueada,         // Valor bloqueado com sucesso
  liberada,          // Caução liberada após devolução
  utilizadaParcialmente, // Parte da caução utilizada
  utilizadaTotalmente,   // Toda a caução utilizada
  naoAplicavel,      // Se o item não exigir caução
}

class AluguelCaucao {
  final double valor;
  final StatusAluguelCaucao status;
  final String? metodoPagamento;
  final String? transacaoId;
  final DateTime? dataBloqueio;
  final DateTime? dataLiberacao;
  final String? motivoRetencao;
  final double? valorRetido;

  AluguelCaucao({
    required this.valor,
    required this.status,
    this.metodoPagamento,
    this.transacaoId,
    this.dataBloqueio,
    this.dataLiberacao,
    this.motivoRetencao,
    this.valorRetido,
  });

  AluguelCaucao copyWith({
    double? valor,
    StatusAluguelCaucao? status,
    String? metodoPagamento,
    String? transacaoId,
    DateTime? dataBloqueio,
    DateTime? dataLiberacao,
    String? motivoRetencao,
    double? valorRetido,
  }) {
    return AluguelCaucao(
      valor: valor ?? this.valor,
      status: status ?? this.status,
      metodoPagamento: metodoPagamento ?? this.metodoPagamento,
      transacaoId: transacaoId ?? this.transacaoId,
      dataBloqueio: dataBloqueio ?? this.dataBloqueio,
      dataLiberacao: dataLiberacao ?? this.dataLiberacao,
      motivoRetencao: motivoRetencao ?? this.motivoRetencao,
      valorRetido: valorRetido ?? this.valorRetido,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'status': status.name,
      'metodoPagamento': metodoPagamento,
      'transacaoId': transacaoId,
      'dataBloqueio': dataBloqueio != null ? Timestamp.fromDate(dataBloqueio!) : null,
      'dataLiberacao': dataLiberacao != null ? Timestamp.fromDate(dataLiberacao!) : null,
      'motivoRetencao': motivoRetencao,
      'valorRetido': valorRetido,
    };
  }

  factory AluguelCaucao.fromMap(Map<String, dynamic> map) {
    DateTime? toDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AluguelCaucao(
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      status: StatusAluguelCaucao.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusAluguelCaucao.naoAplicavel,
      ),
      metodoPagamento: map['metodoPagamento'],
      transacaoId: map['transacaoId'],
      dataBloqueio: toDateTime(map['dataBloqueio']),
      dataLiberacao: toDateTime(map['dataLiberacao']),
      motivoRetencao: map['motivoRetencao'],
      valorRetido: (map['valorRetido'] as num?)?.toDouble(),
    );
  }
}

class Aluguel {
  final String id;
  final String itemId;
  final String itemNome;
  final String itemFotoUrl;
  final String locadorId; // Dono do item
  final String locadorNome;
  final String locatarioId; // Quem está alugando
  final String locatarioNome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double precoTotal;
  final StatusAluguel status;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? observacoesLocatario;
  final String? motivoRecusaLocador;
  final String? contratoId;
  final AluguelCaucao caucao;

  Aluguel({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.itemFotoUrl,
    required this.locadorId,
    required this.locadorNome,
    required this.locatarioId,
    required this.locatarioNome,
    required this.dataInicio,
    required this.dataFim,
    required this.precoTotal,
    required this.status,
    required this.criadoEm,
    required this.caucao,
    this.atualizadoEm,
    this.observacoesLocatario,
    this.motivoRecusaLocador,
    this.contratoId,
  });

  Aluguel copyWith({
    String? id,
    String? itemId,
    String? itemNome,
    String? itemFotoUrl,
    String? locadorId,
    String? locadorNome,
    String? locatarioId,
    String? locatarioNome,
    DateTime? dataInicio,
    DateTime? dataFim,
    double? precoTotal,
    StatusAluguel? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? observacoesLocatario,
    String? motivoRecusaLocador,
    String? contratoId,
    AluguelCaucao? caucao,
  }) {
    return Aluguel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemNome: itemNome ?? this.itemNome,
      itemFotoUrl: itemFotoUrl ?? this.itemFotoUrl,
      locadorId: locadorId ?? this.locadorId,
      locadorNome: locadorNome ?? this.locadorNome,
      locatarioId: locatarioId ?? this.locatarioId,
      locatarioNome: locatarioNome ?? this.locatarioNome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      precoTotal: precoTotal ?? this.precoTotal,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      observacoesLocatario: observacoesLocatario ?? this.observacoesLocatario,
      motivoRecusaLocador: motivoRecusaLocador ?? this.motivoRecusaLocador,
      contratoId: contratoId ?? this.contratoId,
      caucao: caucao ?? this.caucao,
    );
  }
}