import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para dados do perfil público de um usuário
final perfilPublicoProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, usuarioId) async {
  // Simular carregamento de dados do usuário
  await Future.delayed(const Duration(seconds: 1));
  
  // Dados simulados do usuário
  return {
    'id': usuarioId,
    'nome': _getNomeUsuario(usuarioId),
    'fotoUrl': 'https://via.placeholder.com/200x200?text=${_getNomeUsuario(usuarioId)[0]}',
    'cidade': 'São Paulo, SP',
    'verificado': usuarioId == 'user1',
    'sobre': 'Usuário confiável com mais de 2 anos na plataforma. Sempre cuido bem dos itens que alugo e mantenho boa comunicação.',
    'totalItens': _getRandomNumber(5, 25),
    'totalAlugueis': _getRandomNumber(10, 50),
    'reputacao': _getRandomRating(),
    'avaliacoes': _getAvaliacoes(usuarioId),
    'itens': _getItensUsuario(usuarioId),
  };
});

String _getNomeUsuario(String usuarioId) {
  final nomes = {
    'user1': 'João Silva',
    'user2': 'Maria Santos',
    'user3': 'Pedro Oliveira',
    'user4': 'Ana Costa',
    'user5': 'Carlos Ferreira',
  };
  return nomes[usuarioId] ?? 'Usuário $usuarioId';
}

int _getRandomNumber(int min, int max) {
  return min + (DateTime.now().millisecondsSinceEpoch % (max - min));
}

double _getRandomRating() {
  final ratings = [4.2, 4.5, 4.8, 4.1, 4.9, 4.3, 4.7];
  return ratings[DateTime.now().millisecondsSinceEpoch % ratings.length];
}

List<Map<String, dynamic>> _getAvaliacoes(String usuarioId) {
  return [
    {
      'autorNome': 'Maria Santos',
      'autorFoto': 'https://via.placeholder.com/100x100?text=MS',
      'nota': 5,
      'comentario': 'Excelente locador! Item em perfeito estado e entrega pontual.',
      'data': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    },
    {
      'autorNome': 'Pedro Costa',
      'autorFoto': 'https://via.placeholder.com/100x100?text=PC',
      'nota': 4,
      'comentario': 'Muito bom! Recomendo. Comunicação clara e item conforme descrito.',
      'data': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    },
    {
      'autorNome': 'Ana Oliveira',
      'autorFoto': 'https://via.placeholder.com/100x100?text=AO',
      'nota': 5,
      'comentario': 'Perfeito! Super atencioso e o item estava impecável.',
      'data': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
    },
  ];
}

List<Map<String, dynamic>> _getItensUsuario(String usuarioId) {
  return [
    {
      'id': '1',
      'nome': 'Furadeira Bosch Professional',
      'precoPorDia': 25.0,
      'fotos': ['https://via.placeholder.com/300x300?text=Furadeira'],
    },
    {
      'id': '2',
      'nome': 'Parafusadeira Makita',
      'precoPorDia': 20.0,
      'fotos': ['https://via.placeholder.com/300x300?text=Parafusadeira'],
    },
    {
      'id': '3',
      'nome': 'Serra Circular',
      'precoPorDia': 35.0,
      'fotos': ['https://via.placeholder.com/300x300?text=Serra'],
    },
  ];
}
