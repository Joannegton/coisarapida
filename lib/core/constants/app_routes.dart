/// Constantes para as rotas do aplicativo de aluguel de objetos
class AppRoutes {
  // Autenticação
  static const String splash = '/';
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String esqueciSenha = '/esqueci-senha';

  // Principais
  static const String home = '/home';
  static const String buscar = '/buscar';
  static const String favoritos = '/favoritos';
  static const String menu = '/menu';
  static const String listaChats = '/chats';

  // Itens
  static const String anunciarItem = '/anunciar-item';
  static const String detalhesItem = '/item';
  static const String editarItem = '/editar-item';
  static const String meusItens = '/meus-itens';

  // Perfil
  static const String perfilPublico = '/perfil-publico';
  static const String editarPerfil = '/editar-perfil';

  // Aluguéis
  static const String solicitarAluguel = '/solicitar-aluguel';
  static const String meusAlugueis = '/meus-alugueis';
  static const String detalhesAluguel = '/aluguel';
  static const String solicitacoesAluguel = '/solicitacoes-aluguel';
  static const String detalhesSolicitacao = '/detalhes-solicitacao';

  // Chat e Comunicação
  static const String chat = '/chat';

  // Financeiro
  static const String carteira = '/carteira';
  static const String pagamento = '/pagamento';
  static const String extrato = '/extrato';

  // Configurações
  static const String configuracoes = '/configuracoes';
  static const String notificacoes = '/notificacoes';

  // Rotas de segurança
  static const String aceiteContrato = '/aceite-contrato';
  static const String statusAluguel = '/status-aluguel';
  static const String caucao = '/caucao';
  static const String verificacaoFotos = '/verificacao-fotos';
  static const String denuncias = '/denuncias';
  static const String verificacaoResidencia = '/verificacao-residencia';
  static const String verificacaoTelefone = '/verificacao-telefone';

  // Rota de avaliação
  static const String avaliacao = '/avaliacao';

  // Rotas de venda
  static const String comprarItem = '/comprar-item';
  //TODO não implementados
  static const String minhasVendas = '/minhas-vendas';
  static const String minhasCompras = '/minhas-compras';
}
