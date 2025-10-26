import 'package:flutter/material.dart';

//PLACEHOLDER PAGE FOR HIBA'S POKEAPI TAB. 

class PokemonTab extends StatelessWidget {
  const PokemonTab({super.key});

  @override
  Widget build(BuildContext context) {
    // no scaffold here, look in app_shell at _BuildAppBar
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'pokemon api tab (work in progress)',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}