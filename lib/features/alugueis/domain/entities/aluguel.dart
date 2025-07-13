import 'package:coisarapida/features/alugueis/domain/entities/caucao_aluguel.dart';

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

class Aluguel {
  final String id;
  final String itemId;
  final String itemNome;
  final String itemFotoUrl;
  final String locadorId; // dono do item
  final String locadorNome;
  final String locatarioId; // quem ta alugando
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
  final CaucaoAluguel caucao;

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
    CaucaoAluguel? caucao,
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
