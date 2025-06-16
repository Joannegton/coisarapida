import 'package:flutter/material.dart';

class CategoriasSection extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final String categoriaSelecionada;
  final ValueChanged<String> onCategoriaSelecionada;

  const CategoriasSection({
    super.key,
    required this.categorias,
    required this.categoriaSelecionada,
    required this.onCategoriaSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categoria',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione a categoria que melhor descreve seu item',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              final isSelected = categoriaSelecionada == categoria['id'];

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? theme.colorScheme.primary : null,
                child: InkWell(
                  onTap: () {
                    onCategoriaSelecionada(categoria['id']);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        categoria['icone'],
                        size: 32,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categoria['nome'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
