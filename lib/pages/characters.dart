import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universetalk/pages/charactersInfo.dart';

String? apiUrl = dotenv.env['API_URL'];

class CharactersPage extends StatefulWidget {
  final int universeid;
  final String universeName;

  const CharactersPage(
      {super.key, required this.universeid, required this.universeName});

  @override
  State<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends State<CharactersPage> {
  String _token = '';
  List<dynamic> _characters = [];
  bool _isAddingCharacter = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    setState(() {
      _isLoading = true; // Début du chargement
    });
    final storage = await SharedPreferences.getInstance();
    try {
      String? token = storage.getString('token');
      if (token != null) {
        setState(() {
          _token = token;
        });

        final response = await http.get(
          Uri.parse('$apiUrl/universes/${widget.universeid}/characters'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var characters = jsonDecode(response.body);
        setState(() {
          _characters = characters;
        });
      }
    } catch (e) {
      print('Error fetching token: $e');
    } finally {
      setState(() {
        _isLoading = false; // Fin du chargement
      });
    }
  }

  Future<void> _addCharacter(String name, String description) async {
    try {
      setState(() {
        _isAddingCharacter = true; // Début de l'ajout de personnage
      });
      final response = await http.post(
        Uri.parse('$apiUrl/universes/${widget.universeid}/characters'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        // Actualisez la liste des personnages après l'ajout
        _fetchToken();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Character added successfully'),
          ),
        );
      } else {
        print('Failed to add character');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add character'),
          ),
        );
      }
    } catch (e) {
      print('Error adding character: $e');
    } finally {
      setState(() {
        _isAddingCharacter = false; // Fin de l'ajout de personnage
      });
    }
  }

  void _showAddCharacterDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Character'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              )
            ],
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
                _addCharacter(name, '');
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var universeName = widget.universeName;
    var universeid = widget.universeid;

    return Scaffold(
      appBar: AppBar(
        title: Text('$universeName Characters',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isAddingCharacter
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddCharacterDialog,
                ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(), // Indicateur de chargement
                    )
                  : _characters.isEmpty
                      ? const Center(
                          child: Text(
                            'No characters found for this universe.',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _characters.length,
                          itemBuilder: (context, index) {
                            final personnage = _characters[index];
                            return GestureDetector(
                              onTap: () {
                                // Naviguer vers la page CharacterInfoPage avec les infos du personnage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CharacterInfoPage(
                                      characterid: personnage['id'].toInt(),
                                      universeid: universeid,
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
                                      /* child:  ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            15), // Définir le border radius
                                        child: personnage['image'] == "" ||
                                                personnage['image'] == null
                                            ? Image.network(
                                                'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                'https://mds.sprw.dev/image_data/${personnage['image']}',
                                                fit: BoxFit
                                                    .cover, // Ajuste l'image pour couvrir tout le conteneur
                                                alignment: Alignment
                                                    .topCenter, // Alignement de l'image
                                              ),
                                      ), */

                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: personnage['image'] == ""
                                            ? Image.network(
                                                'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                'https://mds.sprw.dev/image_data/${personnage['image']}',
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                                errorBuilder: (BuildContext
                                                        context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  // En cas d'erreur de chargement de l'image, affichez une image de remplacement
                                                  return Image.network(
                                                    'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                                loadingBuilder:
                                                    (BuildContext context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  } else {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  }
                                                },
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
                                          personnage['name'],
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
      ),
    );
  }
}
