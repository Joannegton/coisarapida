import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'conteudo': conteudo,
      'tipo': tipo.name, // Salva o nome do enum como string
      'enviadaEm': FieldValue.serverTimestamp(), // Alterado para usar o timestamp do servidor
      'lida': lida,
      'anexoUrl': anexoUrl,
    };
  }

  factory Mensagem.fromMap(Map<String, dynamic> map) {
    return Mensagem(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      remetenteId: map['remetenteId'] ?? '',
      remetenteNome: map['remetenteNome'] ?? '',
      conteudo: map['conteudo'] ?? '',
      tipo: TipoMensagem.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoMensagem.texto, // Valor padrão
      ),
      enviadaEm: (map['enviadaEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lida: map['lida'] ?? false,
      anexoUrl: map['anexoUrl'],
    );
  }

  factory Mensagem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Mensagem.fromMap(data..['id'] = doc.id);
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
  final Map<String, int> mensagensNaoLidas; // Alterado para Map
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
    this.mensagensNaoLidas = const {}, // Valor padrão como mapa vazio
    required this.criadoEm,
    this.atualizadoEm,
  });

  Chat copyWith({
    String? id,
    String? itemId,
    String? itemNome,
    String? itemFoto,
    String? locadorId,
    String? locadorNome,
    String? locadorFoto,
    String? locatarioId,
    String? locatarioNome,
    String? locatarioFoto,
    Mensagem? ultimaMensagem,
    Map<String, int>? mensagensNaoLidas, // Alterado para Map
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    List<String>? participantes, // Adicionado para Firestore query
  }) {
    return Chat(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemNome: itemNome ?? this.itemNome,
      itemFoto: itemFoto ?? this.itemFoto,
      locadorId: locadorId ?? this.locadorId,
      locadorNome: locadorNome ?? this.locadorNome,
      locadorFoto: locadorFoto ?? this.locadorFoto,
      locatarioId: locatarioId ?? this.locatarioId,
      locatarioNome: locatarioNome ?? this.locatarioNome,
      locatarioFoto: locatarioFoto ?? this.locatarioFoto,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      mensagensNaoLidas: mensagensNaoLidas ?? this.mensagensNaoLidas,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemNome': itemNome,
      'itemFoto': itemFoto,
      'locadorId': locadorId,
      'locadorNome': locadorNome,
      'locadorFoto': locadorFoto,
      'locatarioId': locatarioId,
      'locatarioNome': locatarioNome,
      'locatarioFoto': locatarioFoto,
      'ultimaMensagem': ultimaMensagem?.toMap(),
      'mensagensNaoLidas': mensagensNaoLidas,
      'criadoEm': FieldValue.serverTimestamp(), // Alterado para usar o timestamp do servidor
      'atualizadoEm': FieldValue.serverTimestamp(), // Alterado para usar o timestamp do servidor
      'participantes': [locadorId, locatarioId], // Para facilitar queries
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemNome: map['itemNome'] ?? '',
      itemFoto: map['itemFoto'] ?? '',
      locadorId: map['locadorId'] ?? '',
      locadorNome: map['locadorNome'] ?? '',
      locadorFoto: map['locadorFoto'] ?? '',
      locatarioId: map['locatarioId'] ?? '',
      locatarioNome: map['locatarioNome'] ?? '',
      locatarioFoto: map['locatarioFoto'] ?? '',
      ultimaMensagem: map['ultimaMensagem'] != null ? Mensagem.fromMap(map['ultimaMensagem']) : null,
      mensagensNaoLidas: Map<String, int>.from(map['mensagensNaoLidas'] ?? {}), // Convertido para Map
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      atualizadoEm: (map['atualizadoEm'] as Timestamp?)?.toDate(),
    );
  }

   factory Chat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat.fromMap(data..['id'] = doc.id);
  }
}
