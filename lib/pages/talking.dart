import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universetalk/pages/charactersInfo.dart';

String? apiUrl = dotenv.env['API_URL'];

class TalkingScreen extends StatefulWidget {
  const TalkingScreen({Key? key});

  @override
  State<TalkingScreen> createState() => _TalkingScreenState();
}

class _TalkingScreenState extends State<TalkingScreen> {
  String _token = '';
  List<dynamic> _characters = [];
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadData(); // Charger les données initiales
  }

  Future<void> _loadData() async {
    final storage = await SharedPreferences.getInstance();
    try {
      String? token = storage.getString('token');
      if (token != null) {
        setState(() {
          _token = token;
        });

        final response = await http.get(
          Uri.parse('$apiUrl/conversations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var conversations = jsonDecode(response.body);
        print('conversation: $conversations');

        List<dynamic> characters =
            []; // Liste temporaire pour collecter les personnages

        for (var conversation in conversations) {
          try {
            final characterResponse = await http.get(
              Uri.parse('$apiUrl/characters/${conversation['character_id']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_token',
              },
            );

            if (characterResponse.statusCode == 200) {
              var character = jsonDecode(characterResponse.body);
              characters.add(
                  character); // Ajouter le personnage à la liste temporaire
            } else {
              print(
                  'Failed to fetch character with id: ${conversation['character_id']}');
            }
          } catch (e) {
            print('Error fetching character: $e');
          }
        }

        setState(() {
          _characters =
              characters; // Mettre à jour la liste des personnages une fois que toutes les données ont été récupérées
        });
      }
    } catch (e) {
      print('Error fetching token: $e');
    }
  }

  void _searchconversation(String value) {
    setState(() {
      // Si la valeur de recherche est vide, réinitialisez la liste des conversations pour afficher tous les conversations
      if (value.isEmpty) {
        _loadData(); // Rechargez toutes les conversations
      } else {
        // Sinon, filtrez la liste des conversations en fonction du texte saisi
        _characters = _characters
            .where((character) => character['name']
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talking', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
              kToolbarHeight - 15), // Ajustez la hauteur selon vos besoins
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search conversation...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged:
                        _searchconversation, // Appeler la fonction de recherche lors de la modification du texte
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return GestureDetector(
            onTap: () {
              print('Character ID: ${character['id']}');
              print('Universe ID: ${character['universe_id']}');
              // Naviguer vers la page UniverseInfoPage avec les infos de l'univers
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterInfoPage(
                    characterid: character['id'].toInt(),
                    universeid: character['universe_id'],
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
                    width:
                        MediaQuery.of(context).size.width, // Largeur de l'écran
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: character['image'] == ""
                          ? Image.network(
                              'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              'https://mds.sprw.dev/image_data/${character['image']}',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                // En cas d'erreur de chargement de l'image, affichez une image de remplacement
                                return Image.network(
                                  'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                  fit: BoxFit.cover,
                                );
                              },
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                        character['name'],
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
    );
  }
}
