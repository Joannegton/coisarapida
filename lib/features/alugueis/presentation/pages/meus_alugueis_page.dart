import 'package:coisarapida/features/alugueis/presentation/providers/aluguel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeusAlugueisPage extends ConsumerWidget {
  const MeusAlugueisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meusAlugueisAsync = ref.watch(meusAlugueisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Aluguéis'),
      ),
      body: meusAlugueisAsync.when(
        data: (alugueis) {
          if (alugueis.isEmpty) {
            return const Center(child: Text('Você ainda não possui aluguéis.'));
          }
          return ListView.builder(
            itemCount: alugueis.length,
            itemBuilder: (context, index) {
              final aluguel = alugueis[index];
              // return AluguelCardWidget(aluguel: aluguel); // Use seu widget customizado
              return ListTile( // Exemplo simples
                leading: aluguel.itemFotoUrl.isNotEmpty ? Image.network(aluguel.itemFotoUrl, width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.image_not_supported),
                title: Text(aluguel.itemNome),
                subtitle: Text('Status: ${aluguel.status.name}\nDe: ${aluguel.dataInicio.toLocal().toString().split(' ')[0]} Até: ${aluguel.dataFim.toLocal().toString().split(' ')[0]}'),
                isThreeLine: true,
                onTap: () {
                  // Navegar para detalhes do aluguel
                  // context.push('${AppRoutes.detalhesAluguel}/${aluguel.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro ao carregar seus aluguéis: ${error.toString()}'),
              ElevatedButton(
                onPressed: () => ref.invalidate(meusAlugueisProvider),
                child: const Text('Tentar Novamente'),
              )
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navegar para uma tela de busca de itens para alugar, por exemplo
      //     // context.push(AppRoutes.buscar);
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}