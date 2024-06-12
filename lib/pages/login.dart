import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? apiUrl = dotenv.env['API_URL'];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  bool isLogin = true; // Flag to track Login/Sign In state

  /* requete post login avec les données de l'utilisateur sans utiliser de jsonencode */
  void _postData(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (apiUrl == null) {
      print('API URL is not set in the .env file');
      return;
    }

    var jtm = '$apiUrl/auth';
    var username = usernameController.text;
    var password = passwordController.text;

    final response = await http.post(
      Uri.parse('$apiUrl/auth'),
      body: jsonEncode(
        <String, String>{
          'username': username,
          'password': password,
        },
      ),
    );
    print(response.statusCode);
    // Parse the JSON response body
    var parsedResponse = jsonDecode(response.body);
    // Retrieve the token
    var token = parsedResponse['token'];

    if (response.statusCode == 201) {
      await prefs.setString('token', token);
      Navigator.pushNamed(context, '/home');
      print('Success');
    } else {
      print('Failed');
    }
  }

  void _signup(BuildContext context) async {
    if (apiUrl == null) {
      print('API URL is not set in the .env file');
      return;
    }

    var jtm = '$apiUrl/users';
    print(jtm);

    var username = usernameController.text;
    var password = passwordController.text;
    var email = emailController.text;
    var firstname = firstnameController.text;
    var lastname = lastnameController.text;
    var passwordConfirm = passwordConfirmController.text;

    print(username);
    print(email);
    print(firstname);
    print(lastname);
    print(password);
    print(passwordConfirm);

    if (password != passwordConfirm) {
      print('Passwords do not match');
      return;
    }

    final response = await http.post(Uri.parse('$apiUrl/users'),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
        }));

    if (response.statusCode == 201) {
      // Decode the token if successful
      final decodedToken = jsonDecode(response.body);
      final token = decodedToken['token']; // Assuming token key in response

      // Save the token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, '/login');
      print('Success');
      print('jwt'); // Print success response for debugging
      print(response.body); // Print success response for debugging
      // Write value
    } else {
      print('Failed');
      print(response.body); // Print error response for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: isLogin,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Center text, right-align button
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(fontSize: 40.0),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? 'Sign Up' : 'Back to Login'),
                    ),
                  ],
                ),
              ),
              Visibility(
                  visible: !isLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 40.0),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin ? 'Sign Up' : 'Back to Login'),
                      ),
                    ],
                  )),
              Visibility(
                visible: isLogin,
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'username'),
                ),
              ),
              if (isLogin) const SizedBox(height: 10.0),
              Visibility(
                visible: isLogin,
                child: TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'password'),
                  obscureText: true,
                ),
              ),
              if (isLogin) const SizedBox(height: 10.0),
              Visibility(
                visible: !isLogin,
                child: Column(
                  children: [
                    Visibility(
                      visible: !isLogin,
                      child: TextField(
                        controller: usernameController,
                        decoration:
                            const InputDecoration(labelText: 'username'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstnameController,
                            decoration:
                                const InputDecoration(labelText: 'firstname'),
                          ),
                        ),
                        const SizedBox(
                            width: 10.0), // Add spacing between fields
                        Expanded(
                          child: TextField(
                            controller: lastnameController,
                            decoration:
                                const InputDecoration(labelText: 'lastname'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 10.0), // Add spacing after name fields
                  ],
                ),
              ),
              Visibility(
                visible: !isLogin,
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'email'),
                ),
              ),
              Visibility(
                visible: !isLogin,
                child: TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'password'),
                  obscureText: true,
                ),
              ),
              Visibility(
                visible: !isLogin,
                child: TextField(
                  controller: passwordConfirmController,
                  decoration:
                      const InputDecoration(labelText: 'password confirm'),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () =>
                    isLogin ? _postData(context) : _signup(context),
                child: Text(isLogin
                    ? 'Login'
                    : 'Sign In'), // Text changes based on state
              ),
            ],
          ),
        ),
      ),
    );
  }
}
