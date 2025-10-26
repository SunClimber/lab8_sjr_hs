import 'package:flutter/material.dart';
import 'brewery_tab.dart';
import 'pokemon_tab.dart'; 

// this widget holds the main scaffold and bottom nav bar
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // tracks the active tab

  // key for brewery tab
  final GlobalKey<BreweryTabState> _breweryTabKey = GlobalKey<BreweryTabState>();

  // the list for our two tab pages
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // initialize the tabs list
    _tabs = [
      BreweryTab(key: _breweryTabKey), // tab 0
      const PokemonTab(), // tab 1
    ];
  }

  // called when a bottom nav bar item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- app bar builder methods ---

  /// creates the appbar for the brewery tab (index 0)
  AppBar _buildBreweryAppBar() {
    return AppBar(
      title: const Text('brewery search'),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'fetch data',
          onPressed: () => _breweryTabKey.currentState?.fetchData(),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'clear data',
          onPressed: () => _breweryTabKey.currentState?.clearData(),
        ),
      ],
    );
  }

  /// this method dynamically picks the right app bar
  AppBar _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return _buildBreweryAppBar();
      case 1:
        // pokemon api app bar should go here
        return AppBar(
          title: const Text('pokemon search'),
        );
      default:
        // should never hit this.
        return AppBar(title: const Text('error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // this is our shared scaffold that takes in the AppBar dynamically
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_bar),
            label: 'breweries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.catching_pokemon),
            label: 'pokemon',
          ),
        ],
      ),
    );
  }
}