import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/features/chat/domain/entities/mensagem.dart';

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
  final Map<String, int> mensagensNaoLidas;
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
    this.mensagensNaoLidas = const {},
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
    Map<String, int>? mensagensNaoLidas,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    List<String>? participantes,
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
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'participantes': [locadorId, locatarioId],
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
      mensagensNaoLidas: Map<String, int>.from(map['mensagensNaoLidas'] ?? {}),
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      atualizadoEm: (map['atualizadoEm'] as Timestamp?)?.toDate(),
    );
  }

   factory Chat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat.fromMap(data..['id'] = doc.id);
  }
}
