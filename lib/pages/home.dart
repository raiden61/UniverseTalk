import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universetalk/pages/talking.dart';
import 'package:universetalk/pages/universeinfo.dart';
import 'package:universetalk/pages/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String? apiUrl = dotenv.env['API_URL'];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _token = '';
  List<dynamic> _universes = [];
  bool _isAddingUniverse = false;
  late TextEditingController
      _searchController; // Déclarez le contrôleur comme étant late
  final FocusNode _universeNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _searchController =
        TextEditingController(); // Initialisez le contrôleur ici
  }

  @override
  void dispose() {
    _searchController.dispose(); // Libérez le contrôleur ici
    super.dispose();
  }

  Future<void> _fetchToken() async {
    final storage = await SharedPreferences.getInstance();
    try {
      String? token = storage.getString('token');
      if (token != null) {
        setState(() {
          _token = token;
        });

        final response = await http.get(
          Uri.parse('$apiUrl/universes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var universes = jsonDecode(response.body);
        setState(() {
          _universes = universes;
        });
      }
    } catch (e) {
      print('Error fetching token: $e');
    }
  }

  Future<void> _addUniverse(String name) async {
    try {
      setState(() {
        _isAddingUniverse = true;
      });
      _universeNameFocusNode.unfocus(); // Fermer le clavier
      final response = await http.post(
        Uri.parse('$apiUrl/universes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        // Actualisez la liste des univers après l'ajout
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Universe added successfully!')),
        );
        _fetchToken();
      } else {
        print('Failed to add universe');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to add new Universe. Please try again!')),
        );
      }
    } catch (e) {
      print('Error adding universe: $e');
    } finally {
      setState(() {
        _isAddingUniverse = false;
      });
    }
  }

  void updateUniverseName(int universeId, String newName) {
    setState(() {
      // Mettre à jour le nom de l'univers dans la liste _universes
      _universes.forEach((universe) {
        if (universe['id'] == universeId) {
          universe['name'] = newName;
        }
      });
    });
  }

  void _searchUniverse(String value) {
    setState(() {
      // Si la valeur de recherche est vide, réinitialisez la liste des univers pour afficher tous les univers
      if (value.isEmpty) {
        _fetchToken(); // Rechargez tous les univers
      } else {
        // Sinon, filtrez la liste des univers en fonction du texte saisi
        _universes = _universes
            .where((universe) => universe['name']
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddUniverseDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Universe'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                _addUniverse(name);

                // Fermer le clavier
                FocusScope.of(context).requestFocus(FocusNode());
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  int _selectedIndex = 1; // Set the initial index to 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1
          ? AppBar(
              title: const Text('User', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.deepPurple,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchToken,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight -
                    15), // Ajustez la hauteur selon vos besoins
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search univers...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged:
                              _searchUniverse, // Appeler la fonction de recherche lors de la modification du texte
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _selectedIndex == 1
                    ? HomeScreen(universes: _universes)
                    : _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Talking',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        onTap: _onItemTapped,
      ),
      /* floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddUniverseDialog,
              child: const Icon(Icons.add),
            )
          : null, */
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _isAddingUniverse ? null : _showAddUniverseDialog,
              child: _isAddingUniverse
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    ) // Indicateur de chargement
                  : const Icon(Icons.add),
            )
          : null,
    );
  }

  static const List<Widget> _pages = <Widget>[
    UserScreen(),
    HomeScreen(
      universes: [],
    ),
    TalkingScreen(),
  ];
}

class HomeScreen extends StatelessWidget {
  final List<dynamic> universes;

  const HomeScreen({super.key, required this.universes});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: universes.length,
              itemBuilder: (context, index) {
                final universe = universes[index];
                return GestureDetector(
                  onTap: () {
                    // Naviguer vers la page UniverseInfoPage avec les infos de l'univers
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UniverseInfoPage(
                          universeid: universe['id'].toInt(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Container(
                          height: 200, // Hauteur fixe
                          width: MediaQuery.of(context)
                              .size
                              .width, // Largeur de l'écran
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                15), // Définir le border radius
                            child: universe['image'] == ""
                                ? Image.network(
                                    'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    'https://mds.sprw.dev/image_data/${universe['image']}', // Remplacez data['image'] par le nom de l'image dans vos données JSON
                                    fit: BoxFit
                                        .cover, // Ajuste l'image pour couvrir tout le conteneur
                                    alignment: Alignment
                                        .topCenter, // Alignement de l'image
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              universe['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
