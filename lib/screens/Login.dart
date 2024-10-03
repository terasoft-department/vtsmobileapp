import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import FlutterSecureStorage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Dashboard.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Auth page',
    home: AuthenticationPage(),
    debugShowCheckedModeBanner: false, // This should disable the debug banner
  ));
}

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final storage = const FlutterSecureStorage(); // Initialize FlutterSecureStorage

  Future<void> _login(BuildContext context) async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/login_v1'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final token = jsonResponse['token'];

        if (token != null) {
          // Store the token securely
          await storage.write(key: 'token', value: token);

          // Print the token to console for debugging
          if (kDebugMode) { // Ensure this is only printed in debug mode
            print('Token: $token');
          }

          // Navigate to the dashboard or any other authenticated page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Dashboard(),
            ),
          );
        } else {
          // Show error message if token is null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token not found')),
          );
        }
      } else {
        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 400:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bad Request')),
            );
            break;
          case 401:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid email or password..!!')),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred')),
            );
            break;
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server or network error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Enable scrolling for the entire body
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png', // Update this if you have a different image path
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'TERA VEHICLE TRACKING APP',
                style: TextStyle(
                  color: Colors.blue, // Changed to black for contrast
                  fontSize: 24,
                  fontFamily: 'EuclidCircularA',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: emailController,
                      style: TextStyle(
                        color: Colors.blue[700], // Change text color to blue[700]
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.blue[700], fontFamily: 'EuclidCircularA'), // Change label text color to blue[700]
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[700]!), // Change border color to blue[700]
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[700]!), // Change border color to blue[700]
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      style: TextStyle(
                        color: Colors.blue[700], // Change text color to blue[700]
                      ),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.blue[700], fontFamily: 'EuclidCircularA'), // Change label text color to blue[700]
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[700]!), // Change border color to blue[700]
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue[700]!), // Change border color to blue[700]
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: () => _login(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontFamily: 'EuclidCircularA'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
