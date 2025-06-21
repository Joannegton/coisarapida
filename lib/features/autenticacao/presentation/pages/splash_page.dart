import 'package:coisarapida/features/autenticacao/domain/entities/usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../core/constants/app_routes.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // Aguardar a animação inicial e então verificar a autenticação
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navegarAposAutenticacao();
      }
    });
  }

  void _navegarAposAutenticacao() {
    if (!mounted) return;

    ref.listenManual<AsyncValue<Usuario?>>(authStateProvider, (previous, nextState) {
      nextState.when(
        data: (usuario) {
          if (!mounted) return;
          if (usuario != null) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.login);
          }
        },
        loading: () {},
        error: (error, stackTrace) {
          if (!mounted) return;
          context.go(AppRoutes.login);
        },
      );
    }, fireImmediately: true); // fireImmediately para pegar o estado atual se já resolvido
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/coisa_rapida_logo_png.png'),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Coisa Rápida',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mais rápido que pedir pro visinho',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 64),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withAlpha(204),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
