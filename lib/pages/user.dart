import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'userinfo.dart'; // Importer la page UserInfoPage

String? apiUrl = dotenv.env['API_URL'];

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _token = '';
  List<dynamic> _users = [];
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _fetchToken();
    _searchController = TextEditingController();
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
          Uri.parse('$apiUrl/users'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var users = jsonDecode(response.body);
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      print('Error fetching token: $e');
    }
  }

  void _searchUser(String value) {
    setState(() {
      // Si la valeur de recherche est vide, réinitialisez la liste des utilisateurs pour afficher tous les utilisateurs
      if (value.isEmpty) {
        _fetchToken(); // Rechargez tous les utilisateurs
      } else {
        // Sinon, filtrez la liste des utilisateurs en fonction du texte saisi
        _users = _users
            .where((user) => user['username']
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
          preferredSize: const Size.fromHeight(
              kToolbarHeight - 15), // Ajustez la hauteur selon vos besoins
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search user...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged:
                        _searchUser, // Appeler la fonction de recherche lors de la modification du texte
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Naviguer vers la page UserInfoPage avec les infos de l'utilisateur
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserInfoPage(
                    username: _users[index]['username'],
                    email: _users[index]['email'],
                    firstname: _users[index]['firstname'],
                    lastname: _users[index]['lastname'],
                    token: _token,
                    userId: _users[index]['id'],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  _users[index]['username'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                subtitle: Text(_users[index]['email']),
              ),
            ),
          );
        },
      ),
    );
  }
}
