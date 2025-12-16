import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';

/// 🎬 ÉCRAN DE DÉMARRAGE (SPLASH SCREEN)
/// Affiche le logo RespiraBox pendant le chargement initial
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 🎭 Initialisation des animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    // ⏱️ Navigation après 3 secondes
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(
      Duration(seconds: AppConstants.splashScreenDuration),
    );
    
    if (!mounted) return;
    
    // TODO: Vérifier si l'utilisateur a déjà vu l'onboarding (SharedPreferences)
    // TODO: Vérifier si l'utilisateur est connecté (Firebase Auth)
    
    // Pour l'instant, toujours aller vers l'onboarding
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🫁 Icône poumons (temporaire - sera remplacée par l'asset)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.air,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 📝 Nom de l'application
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 📝 Sous-titre
                Text(
                  AppConstants.appSubtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // ⏳ Indicateur de chargement
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Chargement...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
