import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vtsmobileapp/screens/Login.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTS APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // Set SplashScreen as the home widget
      debugShowCheckedModeBanner: false, // This will now work correctly
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuthPage();
  }

  // Navigate to AuthenticationPage after a delay
  void _navigateToAuthPage() {
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthenticationPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image at the top
            Image.asset(
              'assets/images/logo.png', // Ensure this path is correct
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20),
            // Welcome text below the image
            const Text(
              'TERA VEHICLE TRACKING APP',
              style:TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontFamily: 'EuclidCircularA',
              ),
            ),
            SizedBox(height: 20),
            // Optional: Add an icon or any other widget
            Icon(
              Icons.location_on, // Use the icon you prefer
              size: 50,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            // Optional: Add an icon or any other widget
            Icon(
              Icons.directions_car, // Use the icon you prefer
              size: 50,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
