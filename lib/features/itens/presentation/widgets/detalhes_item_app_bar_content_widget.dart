import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';

class DetalhesItemAppBarContentWidget extends StatelessWidget {
  final Item item;
  final int fotoAtual;
  final ValueChanged<int> onPageChanged;

  const DetalhesItemAppBarContentWidget({
    super.key,
    required this.item,
    required this.fotoAtual,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return FlexibleSpaceBar(
      background: Padding(
        padding: EdgeInsets.only(top: statusBarHeight), // Adiciona padding no topo igual à altura da status bar
        child: Stack(
            children: [
              // Carousel de fotos
              if (item.fotos.isNotEmpty)
                PageView.builder(
                  onPageChanged: onPageChanged,
                  itemCount: item.fotos.length,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(item.fotos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),

              // Indicador de fotos
              if (item.fotos.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      item.fotos.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fotoAtual == index ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),

              // Status de disponibilidade
              Positioned(
                top: 50,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.disponivel ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.disponivel ? 'Disponível' : 'Indisponível',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}