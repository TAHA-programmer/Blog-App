import 'dart:async';
import 'package:blog_app/screens/home_screen.dart';
import 'package:blog_app/screens/option_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Function to check the authentication state of the user
  void _checkAuthState() async {
    auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // If the user is still logged in, navigate to HomeScreen
        _navigateToHomeScreen();
      } else {
        // If the user is logged out, go to OptionScreen
        _navigateToOptionScreen();
      }
    });
  }

  // Navigate to the HomeScreen
  void _navigateToHomeScreen() {
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  // Navigate to the OptionScreen (login/register screen)
  void _navigateToOptionScreen() {
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => option_screen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/blog_image.jpg"),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
