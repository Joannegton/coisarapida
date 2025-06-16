import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:coisarapida/core/errors/exceptions.dart';
import '../models/item_model.dart';
import '../../domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ItemRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> publicarItem(ItemModel item) async {
    try {
      await _firestore.collection('itens').doc(item.id).set(item.toMap());
    } catch (e) {
      throw ServerException('Erro ao publicar item: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadFotos(List<File> fotos, String itemId) async {
    try {
      final List<String> downloadUrls = [];
      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final fileName = 'item_${itemId}_foto_$i.jpg';
        final ref = _storage.ref().child('itens/$itemId/$fileName');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
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
}