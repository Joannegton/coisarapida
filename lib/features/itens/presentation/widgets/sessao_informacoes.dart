import 'package:coisarapida/features/autenticacao/presentation/widgets/campo_texto_customizado.dart';
import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

class InformacoesSection extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController descricaoController;
  final TextEditingController regrasController;

  const InformacoesSection({
    super.key,
    required this.nomeController,
    required this.descricaoController,
    required this.regrasController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Básicas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conte-nos sobre o item que você quer alugar',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          CampoTextoCustomizado(
            controller: nomeController,
            label: 'Nome do item',
            hint: 'Ex: Furadeira Bosch Professional',
            prefixIcon: Icons.label,
            validator: Validatorless.required('Nome é obrigatório'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoTextoCustomizado(
            controller: descricaoController,
            label: 'Descrição',
            hint: 'Descreva o item, estado de conservação, especificações...',
            prefixIcon: Icons.description,
            maxLines: 4,
            validator: Validatorless.required('Descrição é obrigatória'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoTextoCustomizado(
            controller: regrasController,
            label: 'Regras de uso (opcional)',
            hint: 'Ex: Não usar em dias chuvosos, devolver limpo...',
            prefixIcon: Icons.rule,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
