import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // need this for api calls
import 'dart:convert'; // need this for json
import 'package:url_launcher/url_launcher.dart'; // need this to launch urls in browser 

// page for the brewery api
class BreweryTab extends StatefulWidget {
  // we need the key to be passed from the parent
  const BreweryTab({super.key});

  // this is the important part for the globalkey
  @override
  BreweryTabState createState() => BreweryTabState();
}

// made the state class public so appshell.dart can see it
class BreweryTabState extends State<BreweryTab> {
  // controller for the textfield
  final _cityController = TextEditingController();

  // this future will hold our api data
  // it's nullable because we don't have data at first
  Future<List<dynamic>>? _breweryFuture;

  // this method will be called by appshell using the key
  void fetchData() {
    // don't fetch if the textfield is empty
    if (_cityController.text.isEmpty) {
      // show a simple message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Enter A City Name')),
      );
      return;
    }

    // set the state to trigger the futurebuilder
    setState(() {
      _breweryFuture = _getBreweries(_cityController.text);
    });
  }

  // this method will be called by appshell using the key
  void clearData() {
    setState(() {
      _breweryFuture = null; // just set the future to null
      _cityController.clear(); // and clear the text field
    });
  }

  // the actual api call logic
  Future<List<dynamic>> _getBreweries(String city) async {
    // replace spaces with underscores for the api
    final formattedCity = city.trim().replaceAll(' ', '_');
    
    // the url from open brewery db
    final url = Uri.parse(
        'https://api.openbrewerydb.org/v1/breweries?by_city=$formattedCity&per_page=50');

    // waiting for the response
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // if it's ok, parse the json
      // it's a list of objects
      return json.decode(response.body);
    } else {
      // if it fails, throw an error
      throw Exception('failed to load breweries');
    }
  }

  // helper method to launch urls
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      // show an error if we can't launch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('could not launch $urlString')),
      );
    } else {
      await launchUrl(url);
    }
  }

  // helper method for icons
  Widget _getBreweryIcon(String? type) {
    IconData icon;
    switch (type) {
      case 'micro':
        icon = Icons.store_mall_directory_outlined;
        break;
      case 'brewpub':
        icon = Icons.restaurant_outlined;
        break;
      case 'regional':
        icon = Icons.factory_outlined;
        break;
      default:
        icon = Icons.sports_bar;
    }
    return Icon(icon, color: Theme.of(context).primaryColor);
  }


  @override
  void dispose() {
    // clean up the controller when the widget is removed
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // textfield for the city input
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: 'e.g., Milwaukee',
              border: OutlineInputBorder(),
              // a search icon to the textfield
              prefixIcon: Icon(Icons.search),
            ),
            // so we can just press enter on the keyboard
            onSubmitted: (value) => fetchData(),
          ),
          const SizedBox(height: 16), // some space

          // this is where the futurebuilder and listview will go
          Expanded(
            child: _buildResults(), // moved the logic to a new method
          ),
        ],
      ),
    );
  }

  // this widget builds the listview based on the future state
  Widget _buildResults() {
    // if we haven't searched yet, show a placeholder
    if (_breweryFuture == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_bar_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a city and press the arrow button... x to clear.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // if we *have* searched, use a futurebuilder
    return FutureBuilder<List<dynamic>>(
      future: _breweryFuture,
      builder: (context, snapshot) {
        // "loading..." state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // "error!" state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'error! ${snapshot.error}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // "no data" state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_drinks_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'no breweries found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // if we get here, we have data.
        final breweries = snapshot.data!;

        // listview 
        return ListView.builder(
          itemCount: breweries.length,
          itemBuilder: (context, index) {
            final brewery = breweries[index];
            final name = brewery['name'] ?? 'no name';
            final type = brewery['brewery_type'] ?? 'unknown type';
            final city = brewery['city'] ?? 'unknown city';
            final street = brewery['street'] ?? 'no address';
            final websiteUrl = brewery['website_url']; // can be null

            // wrapped the listtile in a card
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                // use our new icon helper
                leading: _getBreweryIcon(type),
                title: Text(name),
                // clean up the subtitle
                subtitle: Text('$street, $city\n($type)'),
                // show 3 lines for our subtitle
                isThreeLine: true,
                // add the website button if the url exists
                trailing: websiteUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'visit website',
                        onPressed: () => _launchURL(websiteUrl),
                      )
                    : null, // if no website, show nothing
              ),
            );
          },
        );
      },
    );
  }
}