import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/screens/auth_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              print('Usuário ${_user.email} deslogado!');
              // go to login
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AuthScreen()));
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: Center(child: Text("Logado como: " + _user.email!)),
    );
  }
}
