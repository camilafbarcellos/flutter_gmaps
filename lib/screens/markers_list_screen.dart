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

  _atualizarLocal(String idLocal, Map<String, dynamic> localMap) {
    _locais.doc(idLocal).update(localMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seus locais'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Color(0xff1A3668),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              print('Usuário ${_user.email} deslogado!');
              // go to login
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AuthScreen()));
            },
            icon: Icon(Icons.logout, color: Colors.white),
          )
        ],
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Color(0xffE01C2F),
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
              return Center(
                child: CircularProgressIndicator(color: Color(0xffE01C2F)),
              );
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
                        String idLocal = item.id;
                        return GestureDetector(
                          onTap: () {
                            _abrirMapa(idLocal);
                          },
                          child: Card(
                            child: ListTile(
                              leading: item['predio'].isEmpty
                                  ? Icon(Icons.house)
                                  : Icon(Icons.apartment),
                              title: item['predio'].isEmpty
                                  ? Text(
                                      '${item['rua']}, ${item['numero']}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    )
                                  : Text(
                                      '${item['predio']}, apto. N.º ${item['apartamento']}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['rua']}, ${item['numero']}'),
                                  Text('Bairro: ${item['bairro']}'),
                                  Text('CEP: ${item['cep']}'),
                                  Text(
                                      '${item['cidade']}, ${item['estado']} - ${item['pais']}'),
                                  if (item['observacao'].isNotEmpty)
                                    Text('Obs.: ${item['observacao']}')
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      // janela de edição
                                      editFormPopup(context, idLocal);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.edit),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // janela de confirmação
                                      confirmationAlert(context, idLocal);
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

  editFormPopup(BuildContext context, String idLocal) async {
    DocumentSnapshot document = await _locais.doc(idLocal).get();
    final TextEditingController _controladorNumero =
        TextEditingController(text: document['numero']);
    final TextEditingController _controladorPredio =
        TextEditingController(text: document['predio']);
    final TextEditingController _controladorApartamento =
        TextEditingController(text: document['apartamento']);
    final TextEditingController _controladorObs =
        TextEditingController(text: document['observacao']);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text("Edição"),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Núm. da rua",
                      icon: Icon(Icons.edit_road),
                    ),
                    controller: _controladorNumero,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Prédio",
                      icon: Icon(Icons.apartment),
                    ),
                    controller: _controladorPredio,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Núm. do apartamento",
                      icon: Icon(Icons.numbers),
                    ),
                    controller: _controladorApartamento,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Observação",
                      icon: Icon(Icons.lightbulb),
                    ),
                    controller: _controladorObs,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                // fechar a janela de diálogo
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text(
                "Salvar",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1A3668),
              ),
              onPressed: () {
                // Cria um mapa com os dados editados
                Map<String, dynamic> localMap = {
                  'numero': _controladorNumero.text,
                  'predio': _controladorPredio.text,
                  'apartamento': _controladorApartamento.text,
                  'observacao': _controladorObs.text,
                };
                // Atualiza o documento no Firebase
                _atualizarLocal(idLocal, localMap);
                // Fechar a janela de diálogo
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  confirmationAlert(BuildContext context, String idLocal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exclusão"),
          content: Text("Você tem certeza que deseja excluir este local?"),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                // fechar a janela de diálogo
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text(
                "Confirmar",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1A3668),
              ),
              onPressed: () {
                // Deleta o documento no Firebase
                _excluirLocal(idLocal);
                // fechar a janela de diálogo
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
}
