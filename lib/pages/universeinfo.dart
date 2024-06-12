import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universetalk/pages/characters.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

String? apiUrl = dotenv.env['API_URL'];

class UniverseInfoPage extends StatefulWidget {
  final int universeid;

  const UniverseInfoPage({
    super.key,
    required this.universeid,
  });

  @override
  _UniverseInfoPageState createState() => _UniverseInfoPageState();
}

class _UniverseInfoPageState extends State<UniverseInfoPage> {
  late TextEditingController _nameController;
  String _token = '';
  Map<String, dynamic>? _universe;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fetchTokenAndData();
  }

  Future<void> _fetchTokenAndData() async {
    final storage = await SharedPreferences.getInstance();
    try {
      String? token = storage.getString('token');
      if (token != null) {
        setState(() {
          _token = token;
        });
      }

      final response = await http.get(
        Uri.parse('$apiUrl/universes/${widget.universeid}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        var universe = jsonDecode(response.body);
        setState(() {
          _universe = universe;
          _nameController.text = universe['name'] ?? '';
        });
      } else {
        print('Failed to load universe data');
      }
    } catch (e) {
      print('Error fetching token or data: $e');
    }
  }

  Future<void> _saveNewName() async {
    final newName = _nameController.text;

    final response = await http.put(
      Uri.parse('$apiUrl/universes/${widget.universeid}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': newName,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
      _fetchTokenAndData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update name')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_universe == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('Loading...', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_universe?['name'] ?? 'Missing Universe name',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharactersPage(
                    universeid: widget.universeid,
                    universeName: _universe?['name'] ?? 'Missing Universe name',
                  ),
                ),
              );
            },
            child: const Text('Characters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 122, 0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Name:',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveNewName,
                  child: const Text('Save new Name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 118, 48, 247),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Image:',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Container(
                  height: 200, // Fixed height
                  width: MediaQuery.of(context).size.width, // Screen width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child:
                        _universe?['image'] == null || _universe?['image'] == ""
                            ? Image.network(
                                'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                'https://mds.sprw.dev/image_data/${_universe?['image']}',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    maxHeight: 250, // Maximum height for the container
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: _universe?['description'] == null ||
                              _universe?['description'].isEmpty
                          ? const Text(
                              'Missing description',
                              style: TextStyle(fontSize: 16),
                            )
                          : Text(
                              _universe?['description'],
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
