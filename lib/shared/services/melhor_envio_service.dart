import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:coisarapida/features/autenticacao/domain/entities/endereco.dart';
import 'package:coisarapida/features/itens/domain/entities/item.dart';
import 'package:coisarapida/core/config/config.dart';

/// Serviço para integração com a API do Melhor Envio
/// Documentação: https://docs.melhorenvio.com.br/reference/introducao
class MelhorEnvioService {
  static String? _accessToken;

  /// Configura o token de acesso da API
  static void configurarToken(String token) {
    _accessToken = token;
  }

  /// Retorna a URL base do Melhor Envio
  static String get _baseUrl => Config.melhorEnvioBaseUrl;

  /// Retorna o token de acesso
  static String get _token => _accessToken ?? Config.melhorEnvioAccessToken;

  /// Calcula frete usando a API do Melhor Envio
  /// Retorna mapa com opções de frete disponíveis
  static Future<Map<String, Map<String, dynamic>>> calcularFrete({
    required Endereco origem,
    required Endereco destino,
    required Item item,
    double? peso, // em kg - opcional, será estimado se não informado
    Map<String, double>? dimensoes, // altura, largura, comprimento em cm
  }) async {
    if (_token.isEmpty) {
      throw Exception('Token de acesso não configurado. Configure MELHOR_ENVIO_ACCESS_TOKEN no .env');
    }

    // Estimar peso e dimensões se não informados
    final pesoEstimado = peso ?? 1; // kg
    final dimensoesEstimadas = dimensoes ?? {
      'altura': 10.0, // cm
      'largura': 15.0, // cm
      'comprimento': 20.0, // cm
    };

    final requestBody = {
      'from': {
        'postal_code': origem.cep.replaceAll('-', ''),
      },
      'to': {
        'postal_code': destino.cep.replaceAll('-', ''),
      },
      'products': [
        {
          'id': item.id,
          'width': dimensoesEstimadas['largura']!.round(),
          'height': dimensoesEstimadas['altura']!.round(),
          'length': dimensoesEstimadas['comprimento']!.round(),
          'weight': pesoEstimado,
          'insurance_value': item.precoVenda ?? item.precoPorDia.toDouble(),
          'quantity': 1,
        }
      ],
      'services': '1,2,17', // PAC=1, SEDEX=2, SEDEX12=17
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shipment/calculate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          'User-Agent': 'CoisaRapida/1.0',
        },
        body: jsonEncode(requestBody), 
      );

      debugPrint('Resposta da API Melhor Envio: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        // Processar resposta da API
        return _processarRespostaFrete(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token de acesso inválido ou expirado');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw Exception('Dados inválidos: ${error['message'] ?? 'Verifique os endereços'}');
      } else {
        throw Exception('Erro na API Melhor Envio: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Erro de conexão com Melhor Envio');
      }
      rethrow;
    }
  }

  /// Converte valor para double de forma segura
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, Map<String, dynamic>> _processarRespostaFrete(List<dynamic> data) {
    final fretes = <String, Map<String, dynamic>>{};

    for (final servico in data) {
      final id = servico['id'].toString();
      final nome = servico['name'] ?? 'Serviço';
      final temErro = servico.containsKey('error');
      final erro = servico['error'];

      // Se tem erro, pular este serviço
      if (temErro) {
        print('Serviço $nome (ID: $id) indisponível: $erro');
        continue;
      }

      final preco = _parseDouble(servico['price']) ?? 0.0;
      final prazo = (servico['delivery_time'] as num?)?.toInt() ?? 0;
      final moeda = servico['currency'] ?? 'BRL';
      final company = servico['company']?['name'] ?? 'Transportadora';

      // Mapear para nossos tipos internos
      String tipoInterno;
      String icone;
      String descricao;

      switch (id) {
        case '1': // PAC
          tipoInterno = 'pac';
          icone = '📦';
          descricao = 'Econômico - $company';
          break;
        case '2': // SEDEX
          tipoInterno = 'sedex';
          icone = '🚀';
          descricao = 'Rápido - $company';
          break;
        case '17': // SEDEX 12 / Mini Envios
          tipoInterno = 'sedex12';
          icone = '⚡';
          descricao = 'Urgente - $company';
          break;
        default:
          tipoInterno = 'outro_$id';
          icone = '📬';
          descricao = '$company';
      }

      fretes[tipoInterno] = {
        'preco': preco,
        'prazo': prazo,
        'nome': nome,
        'descricao': descricao,
        'icone': icone,
        'moeda': moeda,
        'servico_id': id,
        'transportadora': company,
      };
    }

    return fretes;
  }

  /// Busca informações de endereço por CEP usando ViaCEP (fallback)
  static Future<Map<String, dynamic>> buscarEnderecoPorCep(String cep) async {
    try {
      final cepLimpo = cep.replaceAll(RegExp(r'[^\d]'), '');

      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'CoisaRapida/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['erro'] == true) {
          throw Exception('CEP não encontrado');
        }

        return {
          'success': true,
          'endereco': {
            'cep': data['cep'],
            'logradouro': data['logradouro'],
            'bairro': data['bairro'],
            'cidade': data['localidade'],
            'uf': data['uf'],
            'complemento': data['complemento'],
          },
        };
      } else {
        throw Exception('Erro ao buscar CEP');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro ao buscar endereço: $e',
      };
    }
  }

  /// Valida se um CEP é válido usando ViaCEP
  static Future<bool> validarCep(String cep) async {
    try {
      final resultado = await buscarEnderecoPorCep(cep);
      return resultado['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Formata CEP para o padrão XXXXX-XXX
  static String formatarCep(String cep) {
    final limpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpo.length == 8) {
      return '${limpo.substring(0, 5)}-${limpo.substring(5)}';
    }
    return cep;
  }

  /// Lista serviços disponíveis (para debug/admin)
  static Future<List<Map<String, dynamic>>> listarServicos() async {
    if (_token.isEmpty) {
      throw Exception('Token de acesso não configurado');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shipment/services'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
          'User-Agent': 'CoisaRapida/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((servico) => servico as Map<String, dynamic>).toList();
      } else {
        throw Exception('Erro ao listar serviços: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Verifica status da conta Melhor Envio
  static Future<Map<String, dynamic>> verificarConta() async {
    if (_token.isEmpty) {
      throw Exception('Token de acesso não configurado');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/account'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
          'User-Agent': 'CoisaRapida/1.0',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao verificar conta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}

/// Modelo para representar um tipo de frete calculado via Melhor Envio
class FreteMelhorEnvio {
  final String id;
  final String nome;
  final String descricao;
  final double valor;
  final int prazo;
  final String icone;
  final String moeda;
  final String servicoId;

  const FreteMelhorEnvio({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valor,
    required this.prazo,
    required this.icone,
    required this.moeda,
    required this.servicoId,
  });

  factory FreteMelhorEnvio.fromJson(String tipoInterno, Map<String, dynamic> json) {
    // Função auxiliar para converter preço (pode ser string ou double)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return FreteMelhorEnvio(
      id: tipoInterno,
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      valor: parsePrice(json['preco']),
      prazo: (json['prazo'] is int) ? json['prazo'] : int.tryParse(json['prazo']?.toString() ?? '0') ?? 0,
      icone: json['icone'] ?? '📦',
      moeda: json['moeda'] ?? 'BRL',
      servicoId: json['servico_id'] ?? '',
    );
  }

  String get valorFormatado {
    return '${moeda == 'BRL' ? 'R\$' : moeda} ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get prazoFormatado {
    if (id == 'sedex12') {
      return '$prazo hora${prazo > 1 ? 's' : ''}';
    }
    return '$prazo dia${prazo > 1 ? 's' : ''}';
  }
}

/// Extensões úteis para Melhor Envio
extension MelhorEnvioExtensions on double {
  /// Formata valor monetário brasileiro
  String toReal() {
    return 'R\$ ${toStringAsFixed(2).replaceAll('.', ',')}';
  }
}