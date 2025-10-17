import 'dart:convert';
import 'dart:io';
import 'package:coisarapida/core/config/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';

/// Cliente HTTP para chamadas à API backend
class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final FirebaseAuth _auth;

  ApiClient({
    http.Client? client,
    this.baseUrl = Config.apiBaseUrl,
    FirebaseAuth? auth,
  })  : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Obter token de autenticação do Firebase
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('Erro ao obter token: $e');
      return null;
    }
  }

  /// Headers padrão para requisições
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Fazer requisição GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final headers = await _getHeaders(includeAuth: requireAuth);
      
      debugPrint('🌐 GET $uri');
      
      final response = await _client.get(uri, headers: headers);

      return _handleResponse(response);
    } on SocketException {
      throw ServerException('Sem conexão com a internet');
    } catch (e) {
      throw ServerException('Erro na requisição GET: ${e.toString()}');
    }
  }

  /// Fazer requisição POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requireAuth);

      debugPrint('🌐 POST $uri');
      debugPrint('📦 Body: $body');

      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ServerException('Sem conexão com a internet');
    } catch (e) {
      throw ServerException('Erro na requisição POST: ${e.toString()}');
    }
  }

  /// Fazer requisição POST com multipart (upload de arquivos)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'file',
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = requireAuth ? await _getAuthToken() : null;

      debugPrint('🌐 POST (multipart) $uri');

      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ServerException('Sem conexão com a internet');
    } catch (e) {
      throw ServerException('Erro no upload: ${e.toString()}');
    }
  }

  /// Fazer requisição PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requireAuth);

      debugPrint('🌐 PUT $uri');

      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on SocketException {
      throw ServerException('Sem conexão com a internet');
    } catch (e) {
      throw ServerException('Erro na requisição PUT: ${e.toString()}');
    }
  }

  /// Fazer requisição DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requireAuth);

      debugPrint('🌐 DELETE $uri');

      final response = await _client.delete(uri, headers: headers);

      return _handleResponse(response);
    } on SocketException {
      throw ServerException('Sem conexão com a internet');
    } catch (e) {
      throw ServerException('Erro na requisição DELETE: ${e.toString()}');
    }
  }

  /// Processar resposta HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('📨 Response [${response.statusCode}]: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      
      try {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('📄 JSON decodificado: $jsonResponse');
        return jsonResponse;
      } catch (e) {
        throw ServerException('Resposta inválida do servidor');
      }
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Não autorizado');
    } else if (response.statusCode == 404) {
      throw NotFoundException('Recurso não encontrado');
    } else {
      final errorMessage = _extractErrorMessage(response.body);
      throw ServerException(
        'Erro ${response.statusCode}: $errorMessage',
      );
    }
  }

  /// Extrair mensagem de erro do corpo da resposta
  String _extractErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['message'] ?? json['error'] ?? 'Erro desconhecido';
    } catch (e) {
      return responseBody.isNotEmpty ? responseBody : 'Erro desconhecido';
    }
  }

  /// Fechar cliente HTTP
  void dispose() {
    _client.close();
  }
}
