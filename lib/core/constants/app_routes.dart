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
  static const String perfil = '/perfil';
  
  // Itens
  static const String anunciarItem = '/anunciar-item';
  static const String detalhesItem = '/item';
  static const String editarItem = '/editar-item';
  static const String meusItens = '/meus-itens';
  
  // Aluguéis
  static const String solicitarAluguel = '/solicitar-aluguel';
  static const String meusAlugueis = '/meus-alugueis';
  static const String detalhesAluguel = '/aluguel';
  
  // Chat e Comunicação
  static const String chat = '/chat';
  static const String listaChats = '/chats';
  
  // Financeiro
  static const String carteira = '/carteira';
  static const String pagamento = '/pagamento';
  static const String extrato = '/extrato';
  
  // Configurações
  static const String configuracoes = '/configuracoes';
  static const String notificacoes = '/notificacoes';
}
