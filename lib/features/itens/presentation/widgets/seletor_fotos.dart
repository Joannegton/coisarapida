import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/utils/snackbar_utils.dart';

/// Widget para seleção e gerenciamento de fotos do item
class SeletorFotos extends StatefulWidget {
  final List<String> fotosIniciais;
  final Function(List<String>) onFotosChanged;
  final int maxFotos;
  
  const SeletorFotos({
    super.key,
    required this.fotosIniciais,
    required this.onFotosChanged,
    this.maxFotos = 5,
  });

  @override
  State<SeletorFotos> createState() => _SeletorFotosState();
}

class _SeletorFotosState extends State<SeletorFotos> {
  final ImagePicker _picker = ImagePicker();
  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    _fotos = List.from(widget.fotosIniciais);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos do Item',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Adicione fotos para mostrar seu item (mínimo 1, máximo ${widget.maxFotos})',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Dicas para boas fotos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dicas para boas fotos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Use boa iluminação natural\n'
                '• Mostre o item de diferentes ângulos\n'
                '• Inclua acessórios e manuais\n'
                '• Evite fundos bagunçados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Botões de ação
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _fotos.length >= widget.maxFotos ? null : () => _adicionarFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar Foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _fotos.length >= widget.maxFotos ? null : () => _adicionarFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Grid de fotos
        if (_fotos.isNotEmpty) ...[
          Text(
            'Fotos selecionadas (${_fotos.length}/${widget.maxFotos})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGridFotos(),
        ] else
          _buildEstadoVazio(),
      ],
    );
  }

  Widget _buildGridFotos() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _fotos.length,
      itemBuilder: (context, index) => _buildItemFoto(index),
    );
  }

  Widget _buildItemFoto(int index) {
    final foto = _fotos[index];
    final isPrincipal = index == 0;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrincipal 
                ? Border.all(color: Colors.green, width: 3)
                : null,
            image: DecorationImage(
              image: foto.startsWith('http') 
                  ? NetworkImage(foto) 
                  : FileImage(File(foto)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Badge de foto principal
        if (isPrincipal)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Botões de ação
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              if (!isPrincipal)
                GestureDetector(
                  onTap: () => _definirComoPrincipal(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _removerFoto(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma foto adicionada',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque nos botões acima para adicionar',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adicionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _fotos.add(image.path);
        });
        widget.onFotosChanged(_fotos);
        
        SnackBarUtils.mostrarSucesso(
          context, 
          'Foto adicionada! ${_fotos.length}/${widget.maxFotos}',
        );
      }
    } catch (e) {
      SnackBarUtils.mostrarErro(context, 'Erro ao adicionar foto: $e');
    }
  }

  void _removerFoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Foto'),
        content: const Text('Tem certeza que deseja remover esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _fotos.removeAt(index);
              });
              widget.onFotosChanged(_fotos);
              SnackBarUtils.mostrarInfo(context, 'Foto removida');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _definirComoPrincipal(int index) {
    setState(() {
      final foto = _fotos.removeAt(index);
      _fotos.insert(0, foto);
    });
    widget.onFotosChanged(_fotos);
    SnackBarUtils.mostrarSucesso(context, 'Foto definida como principal!');
  }
}
