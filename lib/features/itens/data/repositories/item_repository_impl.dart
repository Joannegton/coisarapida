import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coisarapida/core/services/api_client.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import '../models/item_model.dart';
import '../../domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ApiClient _apiClient;

  ItemRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ApiClient? apiClient,
  })  : _apiClient = apiClient ?? ApiClient(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> publicarItem(ItemModel item) async {
    try {
      
      final itemMap = item.toMap();

      await _firestore.collection('itens').doc(item.id).set(itemMap);
    } catch (e) {
      throw ServerException('Erro ao publicar item: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadFotos(List<File> fotos, String itemId) async {
    try {
      final response = await _apiClient.postMultipart(
        '/imagem/upload',
        fields: {
          'pasta': 'itens',
          'subPasta': itemId,
        },
        files: fotos,
        fileFieldName: 'imagens'
      );

      // O backend retorna uma lista de URLs
      final List<String> downloadUrls = List<String>.from(response['data'] ?? []);

      return downloadUrls;
    } catch (e) {
      throw ServerException('Erro ao fazer upload das fotos: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemModel>> getTodosItens() async {
    try {
      final querySnapshot = await _firestore.collection('itens').orderBy('criadoEm', descending: true).get();
      return querySnapshot.docs.map((doc) {
        try {
          return ItemModel.fromFirestore(doc);
        } catch (e) {
          print("Erro ao converter item ${doc.id}: $e");
          rethrow; // Ou lide com o erro de forma mais específica
        }
      }).toList();
    } catch (e) {
      throw ServerException('Erro ao buscar todos os itens: ${e.toString()}');
    }
  }

  @override
  Stream<List<ItemModel>> getTodosItensStream() {
    return _firestore.collection('itens').orderBy('criadoEm', descending: true).snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        try {
          return ItemModel.fromFirestore(doc);
        } catch (e) {
          print("Erro ao converter item ${doc.id}: $e");
          rethrow;
        }
      }).toList();
    });
  }

  @override
  Future<List<ItemModel>> getItensPorUsuario(String proprietarioId, {int limite = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('itens')
          .where('proprietarioId', isEqualTo: proprietarioId)
          .orderBy('criadoEm', descending: true)
          .limit(limite)
          .get();
      return querySnapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Erro ao buscar itens do usuário $proprietarioId: $e");
      throw ServerException('Erro ao buscar itens do usuário: ${e.toString()}');
    }
  }

  @override
  Future<ItemModel?> getDetalhesItem(String itemId) async {
    try {
      final docSnapshot = await _firestore.collection('itens').doc(itemId).get();
      if (docSnapshot.exists) {
        return ItemModel.fromFirestore(docSnapshot);
      } else {
        return null; // Item não encontrado
      }
    } catch (e) {
      print("Erro ao buscar detalhes do item $itemId: $e");
      throw ServerException('Erro ao buscar detalhes do item: ${e.toString()}');
    }
  }

  @override
  Future<void> atualizarItem(ItemModel item) async {
    try {
      await _firestore.collection('itens').doc(item.id).update(item.toMapForUpdate());
    } catch (e) {
      throw ServerException('Erro ao atualizar item: ${e.toString()}');
    }
  }

  @override
  Future<void> deletarFoto(String fotoUrl) async {
    try {
      // Extrai o caminho da foto a partir da URL
      final ref = _storage.refFromURL(fotoUrl);
      await ref.delete();
    } catch (e) {
      print("Erro ao deletar foto: $e");
      // Não lança exceção para não bloquear a atualização caso a foto já não exista
    }
  }
}