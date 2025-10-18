import 'dart:io';
import 'package:coisarapida/features/itens/data/models/item_model.dart';

abstract class ItemRepository {
  Future<void> publicarItem(ItemModel item);
  Future<void> atualizarItem(ItemModel item);
  Future<List<String>> uploadFotos(List<File> fotos, String itemId);
  Future<void> deletarFoto(String fotoUrl);
  Future<List<ItemModel>> getTodosItens();
  Stream<List<ItemModel>> getTodosItensStream();
  Future<List<ItemModel>> getItensPorUsuario(String proprietarioId, {int limite = 10});
  Future<ItemModel?> getDetalhesItem(String itemId);
}