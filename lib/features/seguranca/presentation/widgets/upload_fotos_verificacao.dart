import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../providers/seguranca_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Widget para upload de fotos de verificação do item
class UploadFotosVerificacao extends ConsumerStatefulWidget {
  final String aluguelId;
  final String itemId;

  const UploadFotosVerificacao({
    super.key,
    required this.aluguelId,
    required this.itemId,
  });

  @override
  ConsumerState<UploadFotosVerificacao> createState() => _UploadFotosVerificacaoState();
}

class _UploadFotosVerificacaoState extends ConsumerState<UploadFotosVerificacao> {
  List<File> _fotosAntes = [];
  List<File> _fotosDepois = [];
  final _observacoesAntesController = TextEditingController();
  final _observacoesDepoisController = TextEditingController();
  bool _fotosAntesSalvas = false;
  bool _fotosDepoisSalvas = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verificacaoState = ref.watch(verificacaoFotosProvider(widget.aluguelId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Verificação do Item',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Tire fotos do item antes e depois do uso para sua proteção',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fotos ANTES do uso
            _buildSecaoFotos(
              titulo: 'Fotos ANTES do uso',
              descricao: 'Documente o estado inicial do item',
              fotos: _fotosAntes,
              observacoesController: _observacoesAntesController,
              onAdicionarFoto: () => _adicionarFoto(true),
              onRemoverFoto: (index) => _removerFoto(true, index),
              onSalvar: _fotosAntesSalvas ? null : () => _salvarFotos(true),
              salvo: _fotosAntesSalvas,
              cor: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // Fotos DEPOIS do uso
            _buildSecaoFotos(
              titulo: 'Fotos DEPOIS do uso',
              descricao: 'Documente o estado final do item',
              fotos: _fotosDepois,
              observacoesController: _observacoesDepoisController,
              onAdicionarFoto: () => _adicionarFoto(false),
              onRemoverFoto: (index) => _removerFoto(false, index),
              onSalvar: _fotosDepoisSalvas ? null : () => _salvarFotos(false),
              salvo: _fotosDepoisSalvas,
              cor: Colors.green,
            ),
            
            if (verificacaoState.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoFotos({
    required String titulo,
    required String descricao,
    required List<File> fotos,
    required TextEditingController observacoesController,
    required VoidCallback onAdicionarFoto,
    required Function(int) onRemoverFoto,
    required VoidCallback? onSalvar,
    required bool salvo,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: cor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera, color: cor, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              const Spacer(),
              if (salvo)
                Icon(Icons.check_circle, color: cor, size: 20),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            descricao,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Grid de fotos
          if (fotos.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length + (fotos.length < 3 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < fotos.length) {
                    // Foto existente
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(fotos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemoverFoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Botão adicionar
                    return GestureDetector(
                      onTap: onAdicionarFoto,
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: cor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: cor),
                            Text(
                              'Adicionar',
                              style: TextStyle(
                                fontSize: 10,
                                color: cor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ] else ...[
            // Placeholder quando não há fotos
            GestureDetector(
              onTap: onAdicionarFoto,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: cor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: cor),
                    const SizedBox(height: 4),
                    Text(
                      'Adicionar fotos (máx. 3)',
                      style: TextStyle(
                        fontSize: 12,
                        color: cor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Campo de observações
          TextField(
            controller: observacoesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Observações sobre o estado do item...',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(8),
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            style: const TextStyle(fontSize: 12),
            enabled: !salvo,
          ),
          
          if (!salvo && fotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSalvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Salvar Fotos',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _adicionarFoto(bool isAntes) {
    // Simular seleção de foto
    setState(() {
      if (isAntes && _fotosAntes.length < 3) {
        // Simular arquivo de foto
        _fotosAntes.add(File('/path/to/simulated/photo_${_fotosAntes.length}.jpg'));
      } else if (!isAntes && _fotosDepois.length < 3) {
        _fotosDepois.add(File('/path/to/simulated/photo_${_fotosDepois.length}.jpg'));
      }
    });
    
    SnackBarUtils.mostrarInfo(
      context, 
      'Foto ${isAntes ? 'antes' : 'depois'} adicionada! (simulação)',
    );
  }

  void _removerFoto(bool isAntes, int index) {
    setState(() {
      if (isAntes) {
        _fotosAntes.removeAt(index);
      } else {
        _fotosDepois.removeAt(index);
      }
    });
  }

  void _salvarFotos(bool isAntes) async {
    try {
      await ref.read(verificacaoFotosProvider(widget.aluguelId).notifier).salvarFotos(
        itemId: widget.itemId,
        fotosAntes: isAntes ? _fotosAntes : null,
        fotosDepois: !isAntes ? _fotosDepois : null,
        observacoesAntes: isAntes ? _observacoesAntesController.text.trim() : null,
        observacoesDepois: !isAntes ? _observacoesDepoisController.text.trim() : null,
      );

      setState(() {
        if (isAntes) {
          _fotosAntesSalvas = true;
        } else {
          _fotosDepoisSalvas = true;
        }
      });

      SnackBarUtils.mostrarSucesso(
        context,
        'Fotos ${isAntes ? 'antes' : 'depois'} salvas com sucesso! ✅',
      );
    } catch (e) {
      SnackBarUtils.mostrarErro(context, 'Erro ao salvar fotos: $e');
    }
  }

  @override
  void dispose() {
    _observacoesAntesController.dispose();
    _observacoesDepoisController.dispose();
    super.dispose();
  }
}
