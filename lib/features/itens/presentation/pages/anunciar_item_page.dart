import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

import '../../../autenticacao/presentation/widgets/campo_texto_customizado.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Tela para anunciar um novo item para aluguel
class AnunciarItemPage extends ConsumerStatefulWidget {
  const AnunciarItemPage({super.key});

  @override
  ConsumerState<AnunciarItemPage> createState() => _AnunciarItemPageState();
}

class _AnunciarItemPageState extends ConsumerState<AnunciarItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controladores dos campos
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoDiaController = TextEditingController();
  final _precoHoraController = TextEditingController();
  final _caucaoController = TextEditingController();
  final _regrasController = TextEditingController();
  
  int _paginaAtual = 0;
  String _categoriaSelecionada = '';
  List<String> _fotosUrls = [];
  bool _aluguelPorHora = false;
  bool _aprovacaoAutomatica = false;
  
  final List<Map<String, dynamic>> _categorias = [
    {'id': 'ferramentas', 'nome': 'Ferramentas', 'icone': Icons.build},
    {'id': 'eletronicos', 'nome': 'Eletrônicos', 'icone': Icons.devices},
    {'id': 'esportes', 'nome': 'Esportes', 'icone': Icons.sports_soccer},
    {'id': 'casa', 'nome': 'Casa & Jardim', 'icone': Icons.home},
    {'id': 'transporte', 'nome': 'Transporte', 'icone': Icons.directions_bike},
    {'id': 'eventos', 'nome': 'Eventos', 'icone': Icons.celebration},
    {'id': 'saude', 'nome': 'Saúde', 'icone': Icons.medical_services},
    {'id': 'outros', 'nome': 'Outros', 'icone': Icons.category},
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoDiaController.dispose();
    _precoHoraController.dispose();
    _caucaoController.dispose();
    _regrasController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anunciar Item'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_paginaAtual + 1) / 4,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (pagina) {
            setState(() {
              _paginaAtual = pagina;
            });
          },
          children: [
            _buildPaginaInformacoes(),
            _buildPaginaCategoria(),
            _buildPaginaFotos(),
            _buildPaginaPrecos(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotoesNavegacao(theme),
    );
  }

  Widget _buildPaginaInformacoes() {
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
            controller: _nomeController,
            label: 'Nome do item',
            hint: 'Ex: Furadeira Bosch Professional',
            prefixIcon: Icons.label,
            validator: Validatorless.required('Nome é obrigatório'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _descricaoController,
            label: 'Descrição',
            hint: 'Descreva o item, estado de conservação, especificações...',
            prefixIcon: Icons.description,
            maxLines: 4,
            validator: Validatorless.required('Descrição é obrigatória'),
          ),
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _regrasController,
            label: 'Regras de uso (opcional)',
            hint: 'Ex: Não usar em dias chuvosos, devolver limpo...',
            prefixIcon: Icons.rule,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaCategoria() {
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
            itemCount: _categorias.length,
            itemBuilder: (context, index) {
              final categoria = _categorias[index];
              final isSelected = _categoriaSelecionada == categoria['id'];
              
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? theme.colorScheme.primary : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _categoriaSelecionada = categoria['id'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        categoria['icone'],
                        size: 32,
                        color: isSelected ? Colors.white : theme.colorScheme.primary,
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

  Widget _buildPaginaFotos() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
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
            'Adicione fotos para mostrar seu item (mínimo 1, máximo 5)',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Grid de fotos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 5, // Máximo 5 fotos
            itemBuilder: (context, index) {
              if (index < _fotosUrls.length) {
                // Foto existente
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(_fotosUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removerFoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
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
                    ),
                  ],
                );
              } else {
                // Placeholder para adicionar foto
                return GestureDetector(
                  onTap: _adicionarFoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicionar\nFoto',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaPrecos() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preços e Configurações',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defina os valores e como será o aluguel',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Tipo de aluguel
          SwitchListTile(
            title: const Text('Aluguel por hora'),
            subtitle: Text(_aluguelPorHora 
                ? 'Permitir aluguel por horas' 
                : 'Apenas aluguel por dias'),
            value: _aluguelPorHora,
            onChanged: (valor) {
              setState(() {
                _aluguelPorHora = valor;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Preço por dia
          CampoTextoCustomizado(
            controller: _precoDiaController,
            label: 'Preço por dia (R\$)',
            hint: '0,00',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: Validatorless.required('Preço por dia é obrigatório'),
          ),
          
          if (_aluguelPorHora) ...[
            const SizedBox(height: 16),
            CampoTextoCustomizado(
              controller: _precoHoraController,
              label: 'Preço por hora (R\$)',
              hint: '0,00',
              prefixIcon: Icons.schedule,
              keyboardType: TextInputType.number,
            ),
          ],
          
          const SizedBox(height: 16),
          
          CampoTextoCustomizado(
            controller: _caucaoController,
            label: 'Caução (R\$) - opcional',
            hint: '0,00',
            prefixIcon: Icons.security,
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 24),
          
          // Aprovação automática
          SwitchListTile(
            title: const Text('Aprovação automática'),
            subtitle: Text(_aprovacaoAutomatica 
                ? 'Pedidos serão aprovados automaticamente' 
                : 'Você aprovará cada pedido manualmente'),
            value: _aprovacaoAutomatica,
            onChanged: (valor) {
              setState(() {
                _aprovacaoAutomatica = valor;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesNavegacao(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_paginaAtual > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _voltarPagina,
                child: const Text('Voltar'),
              ),
            ),
          if (_paginaAtual > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _paginaAtual == 3 ? _publicarItem : _proximaPagina,
              child: Text(_paginaAtual == 3 ? 'Publicar Item' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  void _voltarPagina() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _proximaPagina() {
    if (_validarPaginaAtual()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validarPaginaAtual() {
    switch (_paginaAtual) {
      case 0:
        return _nomeController.text.isNotEmpty && _descricaoController.text.isNotEmpty;
      case 1:
        if (_categoriaSelecionada.isEmpty) {
          SnackBarUtils.mostrarErro(context, 'Selecione uma categoria');
          return false;
        }
        return true;
      case 2:
        if (_fotosUrls.isEmpty) {
          SnackBarUtils.mostrarErro(context, 'Adicione pelo menos uma foto');
          return false;
        }
        return true;
      case 3:
        return _precoDiaController.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _adicionarFoto() {
    // Simular adição de foto
    setState(() {
      _fotosUrls.add('https://via.placeholder.com/300x300?text=Foto+${_fotosUrls.length + 1}');
    });
    SnackBarUtils.mostrarSucesso(context, 'Foto adicionada!');
  }

  void _removerFoto(int index) {
    setState(() {
      _fotosUrls.removeAt(index);
    });
  }

  void _publicarItem() {
    if (_formKey.currentState!.validate() && _validarPaginaAtual()) {
      // Simular publicação
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Publicando item...'),
            ],
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Fechar dialog de loading
        
        SnackBarUtils.mostrarSucesso(
          context,
          'Item publicado com sucesso! 🎉',
        );
        
        context.pop(); // Voltar para tela anterior
      });
    }
  }
}
