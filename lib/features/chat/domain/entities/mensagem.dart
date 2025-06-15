/// Entidade que representa uma mensagem no chat
class Mensagem {
  final String id;
  final String chatId;
  final String remetenteId;
  final String remetenteNome;
  final String conteudo;
  final TipoMensagem tipo;
  final DateTime enviadaEm;
  final bool lida;
  final String? anexoUrl;

  const Mensagem({
    required this.id,
    required this.chatId,
    required this.remetenteId,
    required this.remetenteNome,
    required this.conteudo,
    required this.tipo,
    required this.enviadaEm,
    this.lida = false,
    this.anexoUrl,
  });

  Mensagem copyWith({
    String? id,
    String? chatId,
    String? remetenteId,
    String? remetenteNome,
    String? conteudo,
    TipoMensagem? tipo,
    DateTime? enviadaEm,
    bool? lida,
    String? anexoUrl,
  }) {
    return Mensagem(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      conteudo: conteudo ?? this.conteudo,
      tipo: tipo ?? this.tipo,
      enviadaEm: enviadaEm ?? this.enviadaEm,
      lida: lida ?? this.lida,
      anexoUrl: anexoUrl ?? this.anexoUrl,
    );
  }
}

enum TipoMensagem {
  texto,
  imagem,
  sistema,
}

/// Entidade que representa um chat
class Chat {
  final String id;
  final String itemId;
  final String itemNome;
  final String itemFoto;
  final String locadorId;
  final String locadorNome;
  final String locadorFoto;
  final String locatarioId;
  final String locatarioNome;
  final String locatarioFoto;
  final Mensagem? ultimaMensagem;
  final int mensagensNaoLidas;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  const Chat({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.itemFoto,
    required this.locadorId,
    required this.locadorNome,
    required this.locadorFoto,
    required this.locatarioId,
    required this.locatarioNome,
    required this.locatarioFoto,
    this.ultimaMensagem,
    this.mensagensNaoLidas = 0,
    required this.criadoEm,
    this.atualizadoEm,
  });
}
