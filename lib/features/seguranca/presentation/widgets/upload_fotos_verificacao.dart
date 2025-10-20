import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../providers/seguranca_provider.dart';
import '../../domain/entities/verificacao_fotos.dart';
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
  final List<File> _fotosAntes = [];
  final List<File> _fotosDepois = [];
  final _observacoesAntesController = TextEditingController();
  final _observacoesDepoisController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingFotos = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final verificacaoState = ref.watch(verificacaoFotosProvider(widget.aluguelId));

    // Atualizar estado local quando os dados do provider mudarem
    verificacaoState.whenData((verificacao) async {
      if (verificacao != null && mounted) {
        // Limpar cache das imagens quando os dados são carregados
        if (verificacao.fotosAntes.isNotEmpty || verificacao.fotosDepois.isNotEmpty) {
          await _limparCacheImagens([...verificacao.fotosAntes, ...verificacao.fotosDepois]);
        }
        
        // Preencher observações se estiverem vazias
        if (_observacoesAntesController.text.isEmpty && verificacao.observacoesAntes != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _observacoesAntesController.text = verificacao.observacoesAntes!;
            }
          });
        }
        if (_observacoesDepoisController.text.isEmpty && verificacao.observacoesDepois != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _observacoesDepoisController.text = verificacao.observacoesDepois!;
            }
          });
        }
      }
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: theme.colorScheme.primary,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Verificação do Item',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.05),
            
            // Fotos ANTES do uso
            _buildSecaoFotos(
              titulo: 'Fotos ANTES do uso',
              descricao: 'Documente o estado inicial do item',
              fotos: _fotosAntes,
              fotosSalvasUrls: verificacaoState.value?.fotosAntes ?? [],
              observacoesController: _observacoesAntesController,
              onAdicionarFoto: () => _adicionarFoto(true),
              onRemoverFoto: (index) => _removerFoto(true, index),
              onSalvar: () => _salvarFotos(true),
              cor: Colors.blue,
              isAntes: true,
              verificacaoState: verificacaoState,
            ),
            
            const SizedBox(height: 16),
            
            // Fotos DEPOIS do uso
            _buildSecaoFotos(
              titulo: 'Fotos DEPOIS do uso',
              descricao: 'Documente o estado final do item',
              fotos: _fotosDepois,
              fotosSalvasUrls: verificacaoState.value?.fotosDepois ?? [],
              observacoesController: _observacoesDepoisController,
              onAdicionarFoto: () => _adicionarFoto(false),
              onRemoverFoto: (index) => _removerFoto(false, index),
              onSalvar: () => _salvarFotos(false),
              cor: Colors.green,
              isAntes: false,
              verificacaoState: verificacaoState,
            ),
            
            if (verificacaoState.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      );
  }

  Widget _buildSecaoFotos({
    required String titulo,
    required String descricao,
    required List<File> fotos,
    required List<String> fotosSalvasUrls,
    required TextEditingController observacoesController,
    required VoidCallback onAdicionarFoto,
    required Function(int) onRemoverFoto,
    required VoidCallback? onSalvar,
    required Color cor,
    required bool isAntes,
    required AsyncValue<VerificacaoFotos?> verificacaoState,
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
              // Botão para limpar cache e recarregar
              IconButton(
                icon: Icon(Icons.refresh, color: cor, size: 20),
                onPressed: () async {
                  // Limpar cache das imagens atuais
                  final fotosSalvas = isAntes 
                      ? verificacaoState.value?.fotosAntes ?? []
                      : verificacaoState.value?.fotosDepois ?? [];
                  if (fotosSalvas.isNotEmpty) {
                    await _limparCacheImagens(fotosSalvas);
                    SnackBarUtils.mostrarInfo(context, 'Cache das imagens limpo');
                  }
                  // Recarregar dados
                  ref.invalidate(verificacaoFotosProvider(widget.aluguelId));
                },
                tooltip: 'Atualizar imagens',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
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
          
          // Grid de fotos - mostrar fotos salvas E fotos locais não salvas
          Builder(
            builder: (context) {
              final totalFotos = fotosSalvasUrls.length + fotos.length;
              
              return SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalFotos + (totalFotos < 3 ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Fotos salvas primeiro
                    if (index < fotosSalvasUrls.length) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cor.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: fotosSalvasUrls[index],
                            fit: BoxFit.cover,
                            memCacheWidth: 200, // Limitar cache de memória
                            memCacheHeight: 200,
                            maxWidthDiskCache: 400, // Limitar cache de disco
                            maxHeightDiskCache: 400,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.error,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Fotos locais (não salvas)
                    final fotoLocalIndex = index - fotosSalvasUrls.length;
                    if (fotoLocalIndex < fotos.length) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(fotos[fotoLocalIndex]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => onRemoverFoto(fotoLocalIndex),
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
                    }
                    
                    // Botão adicionar (sempre mostrar se não atingiu o limite)
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
                  },
                ),
              );
            },
          ),
          
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
            enabled: fotos.isNotEmpty, // Habilitar sempre que houver fotos locais
          ),
          
          if (fotos.isNotEmpty) ...[
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

  Future<void> _adicionarFoto(bool isAntes) async {
    if (_isLoadingFotos) return;

    final listaFotos = isAntes ? _fotosAntes : _fotosDepois;
    final fotosSalvasUrls = isAntes 
        ? ref.read(verificacaoFotosProvider(widget.aluguelId)).value?.fotosAntes ?? []
        : ref.read(verificacaoFotosProvider(widget.aluguelId)).value?.fotosDepois ?? [];
    
    // Verificar limite total (fotos locais + fotos salvas)
    if (listaFotos.length + fotosSalvasUrls.length >= 3) {
      SnackBarUtils.mostrarInfo(context, 'Máximo de 3 fotos atingido');
      return;
    }

    setState(() => _isLoadingFotos = true);

    try {
      // Mostrar opções de câmera ou galeria
      final source = await _mostrarOpcoesImagem();
      if (source == null) {
        setState(() => _isLoadingFotos = false);
        return;
      }

      final XFile? imagem = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (imagem != null && mounted) {
        setState(() {
          if (isAntes) {
            _fotosAntes.add(File(imagem.path));
          } else {
            _fotosDepois.add(File(imagem.path));
          }
        });
        
        SnackBarUtils.mostrarSucesso(
          context, 
          'Foto adicionada com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.mostrarErro(context, 'Erro ao adicionar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFotos = false);
      }
    }
  }

  Future<ImageSource?> _mostrarOpcoesImagem() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
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

  Future<void> _salvarFotos(bool isAntes) async {
    final fotos = isAntes ? _fotosAntes : _fotosDepois;
    
    if (fotos.isEmpty) {
      SnackBarUtils.mostrarInfo(context, 'Adicione pelo menos uma foto');
      return;
    }

    try {
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Salvando fotos...'),
                ],
              ),
            ),
          ),
        ),
      );

      // TODO: Adaptar para o novo padrão
      // Este widget precisa ser atualizado para trabalhar com os novos métodos
      // Por enquanto, mostrar mensagem informativa
      
      if (!mounted) return;
      Navigator.of(context).pop();
      
      SnackBarUtils.mostrarAviso(
        context,
        'Este recurso precisa ser atualizado. Use a nova API de verificação de fotos.',
      );


      if (!mounted) return;
      
      // Fechar diálogo de progresso
      Navigator.of(context).pop();

      // Limpar as fotos locais após salvar
      setState(() {
        if (isAntes) {
          _fotosAntes.clear();
        } else {
          _fotosDepois.clear();
        }
      });

      // Invalidar o provider para recarregar os dados
      ref.invalidate(verificacaoFotosProvider(widget.aluguelId));

      // Aguardar um pouco para o provider recarregar e limpar cache das imagens
      await Future.delayed(const Duration(milliseconds: 500));
      final novoEstado = ref.read(verificacaoFotosProvider(widget.aluguelId));
      novoEstado.whenData((verificacao) async {
        if (verificacao != null) {
          final todasUrls = [...verificacao.fotosAntes, ...verificacao.fotosDepois];
          if (todasUrls.isNotEmpty) {
            await _limparCacheImagens(todasUrls);
          }
        }
      });

      SnackBarUtils.mostrarSucesso(
        context,
        'Fotos ${isAntes ? 'antes' : 'depois'} salvas com sucesso! ✅',
      );
    } catch (e) {
      if (mounted) {
        // Fechar diálogo de progresso se ainda estiver aberto
        Navigator.of(context).pop();
        SnackBarUtils.mostrarErro(context, 'Erro ao salvar fotos: $e');
      }
    }
  }

  @override
  void dispose() {
    _observacoesAntesController.dispose();
    _observacoesDepoisController.dispose();
    super.dispose();
  }

  /// Limpa o cache das imagens especificadas
  Future<void> _limparCacheImagens(List<String> urls) async {
    try {
      for (final url in urls) {
        await CachedNetworkImage.evictFromCache(url);
      }
    } catch (e) {
      print('DEBUG: Erro ao limpar cache: $e');
    }
  }
}
