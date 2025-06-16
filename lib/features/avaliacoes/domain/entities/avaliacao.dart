enum TipoAvaliado { usuario, item }

class Avaliacao {
  final String id;
  final String avaliadorId; // UID de quem está avaliando
  final String avaliadorNome;
  final String? avaliadorFotoUrl;
  final String avaliadoId; // UID do usuário avaliado OU ID do item avaliado
  final TipoAvaliado tipoAvaliado; // Se a avaliação é para um usuário ou para um item
  final String? aluguelId; // ID do aluguel relacionado, se aplicável
  final String? itemId; // ID do item, se a avaliação for sobre o item ou um usuário em contexto de um item
  final int nota; // Ex: 1 a 5
  final String? comentario;
  final DateTime data;

  Avaliacao({
    required this.id,
    required this.avaliadorId,
    required this.avaliadorNome,
    this.avaliadorFotoUrl,
    required this.avaliadoId,
    required this.tipoAvaliado,
    this.aluguelId,
    this.itemId,
    required this.nota,
    this.comentario,
    required this.data,
  });

  Avaliacao copyWith({
    String? id,
    String? avaliadorId,
    String? avaliadorNome,
    String? avaliadorFotoUrl,
    String? avaliadoId,
    TipoAvaliado? tipoAvaliado,
    String? aluguelId,
    String? itemId,
    int? nota,
    String? comentario,
    DateTime? data,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      avaliadorId: avaliadorId ?? this.avaliadorId,
      avaliadorNome: avaliadorNome ?? this.avaliadorNome,
      avaliadorFotoUrl: avaliadorFotoUrl ?? this.avaliadorFotoUrl,
      avaliadoId: avaliadoId ?? this.avaliadoId,
      tipoAvaliado: tipoAvaliado ?? this.tipoAvaliado,
      aluguelId: aluguelId ?? this.aluguelId,
      itemId: itemId ?? this.itemId,
      nota: nota ?? this.nota,
      comentario: comentario ?? this.comentario,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Avaliacao && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}