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
    // URL tek bir merkezden yönetiliyor. 
    // Gen 4 (Diamond/Pearl) tarzı piksel art spritelarını çağırıyoruz.
    final String url = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-iv/diamond-pearl/$pokemonId.png';

    return Image.network(
      url,
      height: size,
      width: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // Piksel görünümü korumak için (Bulanıklaşmayı önler)
      
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.blue, width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.catching_pokemon, 
              color: AppColors.blue.withOpacity(0.5), 
              size: size * 0.5
            ),
          ),
        );
      },
    
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: size,
          width: size,
          child: const Center(
            child: SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: AppColors.blue, strokeWidth: 2)
            )
          ),
        );
      },
    );
  }
}