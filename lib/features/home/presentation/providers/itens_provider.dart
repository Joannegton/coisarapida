import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para itens próximos ao usuário
final itensProximosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Simular delay de carregamento
  await Future.delayed(const Duration(seconds: 1));
  
  // Dados mockados de itens para aluguel
  return [
    {
      'id': '1',
      'nome': 'Furadeira Bosch',
      'categoria': 'ferramentas',
      'precoPorDia': 15.0,
      'distancia': 0.8,
      'avaliacao': 4.8,
      'fotos': ['https://via.placeholder.com/300x200?text=Furadeira'],
      'disponivel': true,
      'proprietarioId': 'user1',
      'proprietarioNome': 'João Silva',
    },
    {
      'id': '2',
      'nome': 'Bicicleta Mountain Bike',
      'categoria': 'transporte',
      'precoPorDia': 25.0,
      'distancia': 1.2,
      'avaliacao': 4.5,
      'fotos': ['https://via.placeholder.com/300x200?text=Bike'],
      'disponivel': true,
      'proprietarioId': 'user2',
      'proprietarioNome': 'Maria Santos',
    },
    {
      'id': '3',
      'nome': 'Cadeira de Rodas',
      'categoria': 'saude',
      'precoPorDia': 20.0,
      'distancia': 2.1,
      'avaliacao': 5.0,
      'fotos': ['https://via.placeholder.com/300x200?text=Cadeira'],
      'disponivel': true,
      'proprietarioId': 'user3',
      'proprietarioNome': 'Ana Costa',
    },
    {
      'id': '4',
      'nome': 'Ventilador Industrial',
      'categoria': 'eletronicos',
      'precoPorDia': 30.0,
      'distancia': 0.5,
      'avaliacao': 4.2,
      'fotos': ['https://via.placeholder.com/300x200?text=Ventilador'],
      'disponivel': true,
      'proprietarioId': 'user4',
      'proprietarioNome': 'Carlos Lima',
    },
    {
      'id': '5',
      'nome': 'Mesa de Som',
      'categoria': 'eventos',
      'precoPorDia': 80.0,
      'distancia': 3.0,
      'avaliacao': 4.7,
      'fotos': ['https://via.placeholder.com/300x200?text=Mesa+Som'],
      'disponivel': true,
      'proprietarioId': 'user5',
      'proprietarioNome': 'Pedro Oliveira',
    },
    {
      'id': '6',
      'nome': 'Cortador de Grama',
      'categoria': 'casa',
      'precoPorDia': 35.0,
      'distancia': 1.8,
      'avaliacao': 4.3,
      'fotos': ['https://via.placeholder.com/300x200?text=Cortador'],
      'disponivel': false,
      'proprietarioId': 'user6',
      'proprietarioNome': 'Lucia Ferreira',
    },
  ];
});
