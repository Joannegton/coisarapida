import 'package:cloud_firestore/cloud_firestore.dart';

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