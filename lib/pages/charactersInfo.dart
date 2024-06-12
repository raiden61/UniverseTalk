import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:universetalk/pages/talkingcharacters.dart';

String? apiUrl = dotenv.env['API_URL'];

class CharacterInfoPage extends StatefulWidget {
  final int characterid;
  final int universeid;

  const CharacterInfoPage({
    super.key,
    required this.characterid,
    required this.universeid,
  });

  @override
  _CharacterInfoPageState createState() => _CharacterInfoPageState();
}

class _CharacterInfoPageState extends State<CharacterInfoPage> {
  String _token = '';
  bool _hasConversation = false;
  int _conversationId = -1;
  int _userId = -1;
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _character;

  @override
  void initState() {
    super.initState();
    _fetchTokenAndCheckConversation();
  }

  Future<void> _fetchTokenAndCheckConversation() async {
    print('Character ID in characterinfo: ${widget.characterid}');
    print('Universe ID in characterinfo: ${widget.universeid}');
    final storage = await SharedPreferences.getInstance();
    try {
      String? token = storage.getString('token');
      if (token != null) {
        setState(() {
          _token = token;
        });

        // Decode the token
        Map<String, dynamic> decodedToken = JwtDecoder.decode(_token);
        print('Decoded Token: $decodedToken');

        // Extract user ID (assuming the structure of your token payload)
        Map<String, dynamic> userData = jsonDecode(decodedToken['data']);
        setState(() {
          _userId = userData['id'];
        });

        final getcharacter = await http.get(
          Uri.parse(
              '$apiUrl/universes/${widget.universeid}/characters/${widget.characterid}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        if (getcharacter.statusCode == 200) {
          var character = jsonDecode(getcharacter.body);
          print('Character: $character');
          setState(() {
            _character = character;
          });
        }

        // Vérifier si le personnage a une conversation
        final getconversation = await http.get(
          Uri.parse('$apiUrl/conversations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (getconversation.statusCode == 200) {
          List<dynamic> conversations = jsonDecode(getconversation.body);
          for (var conversation in conversations) {
            if (conversation['character_id'] == widget.characterid &&
                conversation['user_id'] == _userId) {
              setState(() {
                _hasConversation = true;
                _conversationId = conversation['id'];
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching token or checking conversation: $e');
    }
  }

  Future<void> _createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_id': _userId,
          'character_id': widget.characterid,
        }),
      );

      if (response.statusCode == 201) {
        var newConversation = jsonDecode(response.body);
        setState(() {
          _hasConversation = true;
          _conversationId = newConversation['id'];
        });
        _navigateToTalkingPage();
      } else {
        print('Failed to create conversation');
      }
    } catch (e) {
      print('Error creating conversation: $e');
    }
  }

  Future<void> _generateNewDescription() async {
    try {
      final response = await http.put(
        Uri.parse(
            '$apiUrl/universes/${widget.universeid}/characters/${widget.characterid}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New description generated successfully')),
        );
        print('New description generated successfully');
        // Actualisez la description du personnage après la génération
        _fetchTokenAndCheckConversation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate new description')),
        );
        print('Failed to generate new description');
      }
    } catch (e) {
      print('Error generating new description: $e');
    }
  }

  void _navigateToTalkingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TalkingCharactersPage(
          characterid: _character?['id'] ?? -1,
          charactername: _character?['name'] ?? '',
          characterdescription: _character?['description'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
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
        title: Text(_character?['name'] ?? 'Missing Character name',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ElevatedButton(
            onPressed:
                _hasConversation ? _navigateToTalkingPage : _createConversation,
            child: Text(_hasConversation ? 'Talking' : 'Create Conversation'),
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
                Text(
                  _character?['name'] ?? 'Missing Character name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                    child: _character?['image'] == null ||
                            _character?['image'] == ""
                        ? Image.network(
                            'https://1080motion.com/wp-content/uploads/2018/06/NoImageFound.jpg.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            'https://mds.sprw.dev/image_data/${_character?['image']}',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      child: _character?['description'] == null ||
                              _character?['description'].isEmpty
                          ? const Text(
                              'Missing description',
                              style: TextStyle(fontSize: 16),
                            )
                          : Text(
                              _character?['description'],
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _generateNewDescription,
                  child: const Text('Generate new description'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    /* return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        // Ajout du SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Name :',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                widget.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Description :',
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
                child: widget.description.isEmpty
                    ? const Text('No description available')
                    : Text(
                        widget.description,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _hasConversation
                    ? _navigateToTalkingPage
                    : _createConversation,
                child:
                    Text(_hasConversation ? 'Talking' : 'Create Conversation'),
              ),
            ],
          ),
        ),
      ),
    ); */
  }
}
