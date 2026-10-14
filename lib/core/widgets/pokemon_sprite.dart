import 'package:flutter/material.dart';
import 'package:pokelife/core/theme/app_colors.dart';

class PokemonSprite extends StatelessWidget {
  final int pokemonId;
  final double size;

  const PokemonSprite({
    super.key,
    required this.pokemonId,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    // Gen 4 (Diamond/Pearl) tarzı piksel art sprite URL'si
    final String url = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iv/diamond-pearl/$pokemonId.png';

    return Image.network(
      url,
      height: size,
      width: size,
      fit: BoxFit.contain,
      // Piksel art görsellerin bulanıklaşmasını önler (Game Boy / DS hissi için kritik)
      filterQuality: FilterQuality.none, 
      
      // İnternet olmadığında veya yüklenemediğinde gösterilecek yedek (Fallback) widget
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.blue, width: 1.5),
          ),
          child: Center(
            child: Icon(
              Icons.catching_pokemon, 
              color: AppColors.blue.withValues(alpha: 0.6), 
              size: size * 0.45,
            ),
          ),
        );
      },
      
      // İlk yükleme anındaki zarif placeholder (Yükleniyor göstergesi)
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: size,
          width: size,
          child: Center(
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.3,
              child: const CircularProgressIndicator(
                color: AppColors.blue,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}