import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PokemonTab extends StatefulWidget {
  const PokemonTab({super.key});

  @override
  PokemonTabState createState() => PokemonTabState();
}

class PokemonTabState extends State<PokemonTab> {
  final TextEditingController _controller = TextEditingController();
  Future<Pokemon?>? _pokemonFuture;
  Pokemon? _pokemon;

  // public wrappers for AppShell AppBar buttons
  void fetchData() => _handleFetch();
  void clearData() => _handleClear();

  Future<Pokemon?> fetchPokemon(String nameOrId) async {
    final query = nameOrId.toLowerCase().trim();
    if (query.isEmpty) throw Exception('Please enter a Pokémon name or ID.');

    final uri = Uri.https('pokeapi.co', '/api/v2/pokemon/$query');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Pokemon.fromJson(json as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw Exception('Pokémon not found!');
    } else {
      throw Exception('Failed to load Pokémon data (Error ${res.statusCode})');
    }
  }

  void _handleFetch() {
    final name = _controller.text;
    setState(() {
      _pokemonFuture = fetchPokemon(name);
      _pokemon = null;
    });
  }

  void _handleClear() {
    setState(() {
      _controller.clear();
      _pokemonFuture = null;
      _pokemon = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Only TextField remains (title and buttons removed)
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Enter Pokémon name or ID',
              hintText: 'e.g., pikachu or 25',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _handleFetch,
                tooltip: 'Search',
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _handleFetch(),
          ),

          const SizedBox(height: 12),

          // Results area
          Expanded(
            child: _pokemonFuture == null
                ? (_pokemon == null
                    ? const Center(
                        child: Text(
                          'Enter a Pokémon name or ID and press the arrow in the AppBar to fetch.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildPokemonInfo(_pokemon!))
                : FutureBuilder<Pokemon?>(
                    future: _pokemonFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Text('Loading...'));
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(child: Text('No Pokémon found.'));
                      } else {
                        _pokemon = snapshot.data!;
                        return _buildPokemonInfo(_pokemon!);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonInfo(Pokemon pokemon) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  pokemon.name.toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (pokemon.imageUrl.isNotEmpty)
                  Image.network(
                    pokemon.imageUrl,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _infoChip('ID', '${pokemon.id}'),
                    _infoChip('Height', '${pokemon.height} dm'),
                    _infoChip('Weight', '${pokemon.weight} hg'),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Type(s): ${pokemon.types.join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Abilities: ${pokemon.abilities.join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final String imageUrl;
  final List<String> types;
  final List<String> abilities;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.imageUrl,
    required this.types,
    required this.abilities,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final typesList = (json['types'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['type']['name'] as String)
        .toList();

    final abilitiesList = (json['abilities'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['ability']['name'] as String)
        .toList();

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      imageUrl: (json['sprites'] != null && json['sprites']['front_default'] != null)
          ? json['sprites']['front_default'] as String
          : '',
      types: typesList,
      abilities: abilitiesList,
    );
  }
}
