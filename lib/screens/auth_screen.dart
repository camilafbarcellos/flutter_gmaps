import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'menu.dart';
import 'login_or_register_toggle.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return AuthScreenState();
  }
}

class AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          // user logged in
          if (snapshot.hasData) {
            return NavigationOptions();
          }
          //user not logged in
          else {
            return LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}
