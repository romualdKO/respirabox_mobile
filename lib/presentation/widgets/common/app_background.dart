import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Fond dégradé doux (blanc -> teal très clair) utilisé sur les écrans
/// d'accueil/auth pour un rendu "médical rassurant" plutôt qu'un blanc plat.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0F9F8),
            AppColors.backgroundLight,
          ],
        ),
      ),
      child: child,
    );
  }
}
