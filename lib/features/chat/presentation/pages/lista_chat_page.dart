import 'package:coisarapida/features/chat/presentation/widget/card_chat_widget.dart';
import 'package:coisarapida/features/chat/presentation/widget/sem_conversas_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';

class ListaChatsPage extends ConsumerWidget {
  const ListaChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatsState = ref.watch(chatsProvider);
    
    return Scaffold( 
      appBar: AppBar(
        title: Text(
          'Conversas', 
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: chatsState.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const SemConversasWidget();
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(chatsProvider.future),
              child: ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) => CardChatWidget(chat: chats[index]),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ // TODO arrumar o erro
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar chats: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(chatsProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
