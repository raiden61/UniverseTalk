import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String? apiUrl = dotenv.env['API_URL'];

class UserInfoPage extends StatefulWidget {
  final String username;
  final String email;
  final String firstname;
  final String lastname;
  final String token;
  final int userId;

  const UserInfoPage({
    Key? key,
    required this.username,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;

  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _firstnameController = TextEditingController(text: widget.firstname);
    _lastnameController = TextEditingController(text: widget.lastname);

    _checkIfCurrentUser();
  }

  Future<void> _checkIfCurrentUser() async {
    // Decode the token
    Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);

    // Extract user ID from the token payload
    Map<String, dynamic> userData = jsonDecode(decodedToken['data']);
    int decodedUserId = userData['id'];

    setState(() {
      _isCurrentUser = (decodedUserId == widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              enabled: _isCurrentUser, // Enable editing only for current user
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              enabled: _isCurrentUser, // Enable editing only for current user
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _firstnameController,
              enabled: _isCurrentUser, // Enable editing only for current user
              decoration: const InputDecoration(labelText: 'Firstname'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lastnameController,
              enabled: _isCurrentUser, // Enable editing only for current user
              decoration: const InputDecoration(labelText: 'Lastname'),
            ),
            const SizedBox(height: 20),
            if (_isCurrentUser) // Show update button only for current user
              ElevatedButton(
                onPressed: () => _updateUser(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 118, 48, 247),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update User'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUser() async {
    try {
      final Map<String, dynamic> userData = {
        "username": _usernameController.text,
        "email": _emailController.text,
        "firstname": _firstnameController.text,
        "lastname": _lastnameController.text,
      };

      final response = await http.put(
        Uri.parse(
            '$apiUrl/users/${widget.userId}'), // Replace with your API endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        // Handle success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
          ),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user'),
          ),
        );
      }
    } catch (e) {
      print('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating user'),
        ),
      );
    }
  }
}
