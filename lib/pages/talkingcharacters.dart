import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universetalk/pages/charactersInfo.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:jwt_decoder/jwt_decoder.dart';

String? apiUrl = dotenv.env['API_URL'];

class TalkingCharactersPage extends StatefulWidget {
  final int characterid;
  final String charactername;
  final String characterdescription;

  const TalkingCharactersPage({
    super.key,
    required this.characterid,
    required this.charactername,
    required this.characterdescription,
  });

  @override
  _TalkingCharactersPageState createState() => _TalkingCharactersPageState();
}

class _TalkingCharactersPageState extends State<TalkingCharactersPage> {
  String _token = '';
  List<dynamic> _allconversations = [];
  List<dynamic> _filteredConversations = [];
  List<dynamic> _refreshIA = [];
  int _userId = 0;
  int _idconversation = 0;
  List<dynamic> _messages = [];
  TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

        // Decode the token
        Map<String, dynamic> decodedToken = JwtDecoder.decode(_token);

        // Extract user ID (assuming the structure of your token payload)
        Map<String, dynamic> userData = jsonDecode(decodedToken['data']);
        setState(() {
          _userId = userData['id'];
        });

        final response = await http.get(
          Uri.parse('$apiUrl/conversations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var allconversations = jsonDecode(response.body);
        setState(() {
          _allconversations = allconversations;
          _filteredConversations = _allconversations.where((conversation) {
            return conversation['character_id'] == widget.characterid &&
                conversation['user_id'] == _userId;
          }).toList();
        });
        setState(() {
          _idconversation = _filteredConversations[0]['id'];
        });
        // Get all messages
        final messageResponse = await http.get(
          Uri.parse('$apiUrl/conversations/$_idconversation/messages'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
        var message = jsonDecode(messageResponse.body);
        setState(() {
          _messages = message;
        });
      }
    } catch (e) {
      print('Error fetching token: $e');
    }
  }

  Future<void> _sendMessage() async {
    var messageByHuman = _messageController.text;
    if (messageByHuman.isEmpty) {
      return;
    }

    setState(() {
      // Ajouter le message localement pour affichage immédiat
      _messages.add({'content': messageByHuman, 'is_sent_by_human': true});
      _messageController.clear(); // Vider le champ de saisie
      _isLoading = true; // Activer l'état de chargement
    });

    // Fermer le clavier
    FocusScope.of(context).unfocus();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/conversations/$_idconversation/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'content': messageByHuman}),
      );

      if (response.statusCode == 200) {
        // Mettre à jour les messages après l'envoi
        _fetchMessages();
        messageByHuman = '';
      }
      _scrollToBottom(); // Faire défiler vers le bas après la mise à jour des messages
    } catch (e) {
      print('Error sending message: $e');
      messageByHuman = '';
    } finally {
      setState(() {
        _isLoading = false; // Désactiver l'état de chargement
        _fetchMessages();
        _scrollToBottom(); // Faire défiler vers le bas après la mise à jour des messages
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/conversations/$_idconversation/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      var message = jsonDecode(response.body);
      setState(() {
        _messages = message;
      });
      _scrollToBottom(); // Faire défiler vers le bas après la mise à jour des messages
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var charactername = widget.charactername;
    var characterdescription = widget.characterdescription;

    return Scaffold(
      appBar: AppBar(
        title: Text(charactername, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages found for this conversation.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length +
                        (_isLoading
                            ? 1
                            : 0), // Ajouter un élément pour l'animation si en chargement
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        // Afficher un widget de chargement si en cours de chargement
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 10, right: 70, left: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 118, 48, 247),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DefaultTextStyle(
                              style: const TextStyle(fontSize: 14.0),
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  WavyAnimatedText('...'),
                                ],
                                isRepeatingAnimation: true,
                                onTap: () {
                                  print("Tap Event");
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      var message = _messages[index];
                      bool isSentByHuman = message['is_sent_by_human'];
                      if (!isSentByHuman && index == _messages.length - 1) {
                        // Si le message n'est pas envoyé par l'utilisateur et c'est le dernier message
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 10, right: 20, left: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Assure que le Row prend la taille minimale requise
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 118, 48, 247),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      message['content'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(0),
                                      decoration: const BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 118, 48, 247),
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isRefreshing
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            ) // Indicateur de chargement
                                          : IconButton(
                                              icon: const Icon(Icons.refresh,
                                                  color: Colors.white),
                                              iconSize: 25,
                                              onPressed: _refreshMessage,
                                            ),
                                    ),
                                    /* const Text(
                                      'Refresh',
                                      style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 118, 48, 247),
                                        fontSize: 12,
                                      ),
                                    ), */
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isSentByHuman
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: isSentByHuman
                              ? const EdgeInsets.only(
                                  top: 10, left: 70, right: 10)
                              : const EdgeInsets.only(
                                  top: 10, right: 70, left: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSentByHuman
                                ? const Color.fromARGB(255, 255, 122, 0)
                                : const Color.fromARGB(255, 118, 48, 247),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message['content'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    23), // Ajouter un rayon de bordure au conteneur
                color:
                    Colors.grey[200], // Changer la couleur de fond du conteneur
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                20), // Ajouter un rayon de bordure à l'entrée de texte
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(120, 0, 0, 0)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        )),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, 255, 122, 0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.north_rounded, size: 30),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMessage() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      final response = await http.put(
        Uri.parse('$apiUrl/conversations/$_idconversation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      var refreshIA = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Mettre à jour les messages après l'envoi
        _fetchMessages();
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regenerate last message successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error regenerating last message')),
        );
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
}
