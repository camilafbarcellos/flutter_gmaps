import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/auth_screen.dart';
import '/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkersListScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MarkersListScreenState();
  }
}

class MarkersListScreenState extends State<MarkersListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _user = FirebaseAuth.instance.currentUser!;
  final CollectionReference _locais =
      FirebaseFirestore.instance.collection('locais');

  _abrirMapa(String idLocal) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MapScreen(idLocal: idLocal)));
  }

  _adicionarLocal() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen()));
  }

  _excluirLocal(String idLocal) {
    _locais.doc(idLocal).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locais de: ${_user.email}'),
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Color(0xff1A3668),
        onPressed: () {
          _adicionarLocal();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _locais.snapshots(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              List<DocumentSnapshot> locais = [];
              var querySnapshot = snapshot.data;
              if (querySnapshot != null) {
                locais = querySnapshot.docs.toList();
              }
              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: locais.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot item = locais[index];
                        String titulo = item['titulo'];
                        String idLocal = item.id;
                        return GestureDetector(
                          onTap: () {
                            _abrirMapa(idLocal);
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(titulo),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      _excluirLocal(idLocal);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.remove_circle,
                                        color: Color(0xffE01C2F),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              );
          }
        },
      ),
    );
  }
}
