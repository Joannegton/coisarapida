import 'package:flutter/material.dart';

/// Classe para gerenciar as localizações do app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ];

  // Strings da aplicação
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get appSubtitle => _localizedValues[locale.languageCode]!['appSubtitle']!;
  String get welcomeBack => _localizedValues[locale.languageCode]!['welcomeBack']!;
  String get loginSubtitle => _localizedValues[locale.languageCode]!['loginSubtitle']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get enterEmail => _localizedValues[locale.languageCode]!['enterEmail']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get enterPassword => _localizedValues[locale.languageCode]!['enterPassword']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get signIn => _localizedValues[locale.languageCode]!['signIn']!;
  String get or => _localizedValues[locale.languageCode]!['or']!;
  String get continueWithGoogle => _localizedValues[locale.languageCode]!['continueWithGoogle']!;
  String get dontHaveAccount => _localizedValues[locale.languageCode]!['dontHaveAccount']!;
  String get signUp => _localizedValues[locale.languageCode]!['signUp']!;
  String get createAccount => _localizedValues[locale.languageCode]!['createAccount']!;
  String get createAccountSubtitle => _localizedValues[locale.languageCode]!['createAccountSubtitle']!;
  String get fullName => _localizedValues[locale.languageCode]!['fullName']!;
  String get enterFullName => _localizedValues[locale.languageCode]!['enterFullName']!;
  String get confirmPassword => _localizedValues[locale.languageCode]!['confirmPassword']!;
  String get enterPasswordAgain => _localizedValues[locale.languageCode]!['enterPasswordAgain']!;
  String get acceptTerms => _localizedValues[locale.languageCode]!['acceptTerms']!;
  String get termsOfUse => _localizedValues[locale.languageCode]!['termsOfUse']!;
  String get and => _localizedValues[locale.languageCode]!['and']!;
  String get privacyPolicy => _localizedValues[locale.languageCode]!['privacyPolicy']!;
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]!['alreadyHaveAccount']!;
  String get signInButton => _localizedValues[locale.languageCode]!['signInButton']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get emailRequired => _localizedValues[locale.languageCode]!['emailRequired']!;
  String get validEmail => _localizedValues[locale.languageCode]!['validEmail']!;
  String get passwordRequired => _localizedValues[locale.languageCode]!['passwordRequired']!;
  String get nameRequired => _localizedValues[locale.languageCode]!['nameRequired']!;
  String get nameMinLength => _localizedValues[locale.languageCode]!['nameMinLength']!;
  String get passwordMinLength => _localizedValues[locale.languageCode]!['passwordMinLength']!;
  String get confirmPasswordRequired => _localizedValues[locale.languageCode]!['confirmPasswordRequired']!;
  String get passwordsDontMatch => _localizedValues[locale.languageCode]!['passwordsDontMatch']!;
  String get mustAcceptTerms => _localizedValues[locale.languageCode]!['mustAcceptTerms']!;
  String get accountCreatedSuccess => _localizedValues[locale.languageCode]!['accountCreatedSuccess']!;
  String get signingIn => _localizedValues[locale.languageCode]!['signingIn']!;
  String get creatingAccount => _localizedValues[locale.languageCode]!['creatingAccount']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'appTitle': 'Coisa Rápida',
      'appSubtitle': 'Entregas urbanas instantâneas',
      'welcomeBack': 'Bem-vindo de volta!',
      'loginSubtitle': 'Entre na sua conta para continuar',
      'email': 'Email',
      'enterEmail': 'Digite seu email',
      'password': 'Senha',
      'enterPassword': 'Digite sua senha',
      'forgotPassword': 'Esqueci minha senha',
      'signIn': 'Entrar',
      'or': 'ou',
      'continueWithGoogle': 'Continuar com Google',
      'dontHaveAccount': 'Não tem uma conta? ',
      'signUp': 'Cadastre-se',
      'createAccount': 'Criar Conta',
      'createAccountSubtitle': 'Preencha os dados abaixo para começar',
      'fullName': 'Nome completo',
      'enterFullName': 'Digite seu nome completo',
      'confirmPassword': 'Confirmar senha',
      'enterPasswordAgain': 'Digite sua senha novamente',
      'acceptTerms': 'Eu aceito os ',
      'termsOfUse': 'Termos de Uso',
      'and': ' e a ',
      'privacyPolicy': 'Política de Privacidade',
      'alreadyHaveAccount': 'Já tem uma conta? ',
      'signInButton': 'Fazer login',
      'home': 'Início',
      'profile': 'Perfil',
      'settings': 'Configurações',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',
      'emailRequired': 'Email é obrigatório',
      'validEmail': 'Digite um email válido',
      'passwordRequired': 'Senha é obrigatória',
      'nameRequired': 'Nome é obrigatório',
      'nameMinLength': 'Nome deve ter pelo menos 2 caracteres',
      'passwordMinLength': 'Senha deve ter pelo menos 6 caracteres',
      'confirmPasswordRequired': 'Confirmação de senha é obrigatória',
      'passwordsDontMatch': 'Senhas não coincidem',
      'mustAcceptTerms': 'Você deve aceitar os termos de uso',
      'accountCreatedSuccess': 'Conta criada com sucesso! Verifique seu email.',
      'signingIn': 'Entrando...',
      'creatingAccount': 'Criando conta...',
    },
    'en': {
      'appTitle': 'Coisa Rápida',
      'appSubtitle': 'Instant urban deliveries',
      'welcomeBack': 'Welcome back!',
      'loginSubtitle': 'Sign in to your account to continue',
      'email': 'Email',
      'enterEmail': 'Enter your email',
      'password': 'Password',
      'enterPassword': 'Enter your password',
      'forgotPassword': 'Forgot my password',
      'signIn': 'Sign In',
      'or': 'or',
      'continueWithGoogle': 'Continue with Google',
      'dontHaveAccount': 'Don\'t have an account? ',
      'signUp': 'Sign up',
      'createAccount': 'Create Account',
      'createAccountSubtitle': 'Fill in the details below to get started',
      'fullName': 'Full name',
      'enterFullName': 'Enter your full name',
      'confirmPassword': 'Confirm password',
      'enterPasswordAgain': 'Enter your password again',
      'acceptTerms': 'I accept the ',
      'termsOfUse': 'Terms of Use',
      'and': ' and the ',
      'privacyPolicy': 'Privacy Policy',
      'alreadyHaveAccount': 'Already have an account? ',
      'signInButton': 'Sign in',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'emailRequired': 'Email is required',
      'validEmail': 'Enter a valid email',
      'passwordRequired': 'Password is required',
      'nameRequired': 'Name is required',
      'nameMinLength': 'Name must have at least 2 characters',
      'passwordMinLength': 'Password must have at least 6 characters',
      'confirmPasswordRequired': 'Password confirmation is required',
      'passwordsDontMatch': 'Passwords don\'t match',
      'mustAcceptTerms': 'You must accept the terms of use',
      'accountCreatedSuccess': 'Account created successfully! Check your email.',
      'signingIn': 'Signing in...',
      'creatingAccount': 'Creating account...',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
