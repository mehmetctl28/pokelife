import 'package:flutter/material.dart';
import 'package:pokelife/app/app.dart';

void main() async {
  // Provider'lar içindeki SharedPreferences (kayıt) işlemlerinin 
  // çökmemesi için motoru önden başlatıyoruz.
  WidgetsFlutterBinding.ensureInitialized(); 
  
  runApp(const PokelifeApp());
}