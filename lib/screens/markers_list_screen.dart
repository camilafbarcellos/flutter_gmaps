import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gmaps/services/user_service.dart';
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
  final _user = UserService().getUser();
  final CollectionReference _locais =
      FirebaseFirestore.instance.collection('locais');
  String? _filtroCorretor;
  String? _filtroPredio;
  String? _filtroBairro;
  String? _filtroCidade;

  _abrirMapa(String idLocal) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MapScreen(idLocal: idLocal)));
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
        title: Image.asset(
          'lib/logos/remax-white.png',
          width: 150,
        ),
        centerTitle: true,
        backgroundColor: Color(0xff1A3668),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(_user.photoURL!),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              print('Usuário ${_user.email} deslogado!');
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
          Icons.filter_list,
          color: Colors.white,
        ),
        backgroundColor: Color(0xffE01C2F),
        onPressed: () {
          filterFormPopup();
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
                locais = querySnapshot.docs.where((DocumentSnapshot doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final corretor = data['corretor'] as String?;
                  final predio = data['predio'] as String?;
                  final bairro = data['bairro'] as String?;
                  final cidade = data['cidade'] as String?;

                  return (_filtroCorretor == null ||
                          corretor != null &&
                              corretor
                                  .toLowerCase()
                                  .contains(_filtroCorretor!.toLowerCase())) &&
                      (_filtroPredio == null ||
                          predio != null &&
                              predio
                                  .toLowerCase()
                                  .contains(_filtroPredio!.toLowerCase())) &&
                      (_filtroBairro == null ||
                          bairro != null &&
                              bairro
                                  .toLowerCase()
                                  .contains(_filtroBairro!.toLowerCase())) &&
                      (_filtroCidade == null ||
                          cidade != null &&
                              cidade
                                  .toLowerCase()
                                  .contains(_filtroCidade!.toLowerCase()));
                }).toList();
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
                                    Text('Obs.: ${item['observacao']}'),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline),
                                      Text('${item['corretor']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))
                                    ],
                                  )
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      editFormPopup(context, idLocal);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.edit),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
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

  filterFormPopup() async {
    final TextEditingController _controladorCorretor =
        TextEditingController(text: _filtroCorretor);
    final TextEditingController _controladorPredio =
        TextEditingController(text: _filtroPredio);
    final TextEditingController _controladorBairro =
        TextEditingController(text: _filtroBairro);
    final TextEditingController _controladorCidade =
        TextEditingController(text: _filtroCidade);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filtrar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _controladorCorretor,
                decoration: InputDecoration(
                  labelText: "Corretor",
                  icon: Icon(Icons.person_outline),
                ),
              ),
              TextField(
                controller: _controladorPredio,
                decoration: InputDecoration(
                  labelText: "Prédio",
                  icon: Icon(Icons.apartment),
                ),
              ),
              TextField(
                controller: _controladorBairro,
                decoration: InputDecoration(
                  labelText: "Bairro",
                  icon: Icon(Icons.maps_home_work),
                ),
              ),
              TextField(
                controller: _controladorCidade,
                decoration: InputDecoration(
                  labelText: "Cidade",
                  icon: Icon(Icons.location_city),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Resetar"),
              onPressed: () {
                // Reseta os filtros
                _controladorCorretor.clear();
                _controladorPredio.clear();
                _controladorBairro.clear();
                _controladorCidade.clear();
                setState(() {
                  _filtroCorretor = null;
                  _filtroPredio = null;
                  _filtroBairro = null;
                  _filtroCidade = null;
                });
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text(
                "Aplicar",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1A3668),
              ),
              onPressed: () {
                setState(() {
                  _filtroCorretor = _controladorCorretor.text.isEmpty
                      ? null
                      : _controladorCorretor.text;
                  _filtroPredio = _controladorPredio.text.isEmpty
                      ? null
                      : _controladorPredio.text;
                  _filtroBairro = _controladorBairro.text.isEmpty
                      ? null
                      : _controladorBairro.text;
                  _filtroCidade = _controladorCidade.text.isEmpty
                      ? null
                      : _controladorCidade.text;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  editFormPopup(BuildContext context, String idLocal) async {
    // captura o local pelo id
    DocumentSnapshot document = await _locais.doc(idLocal).get();
    final String corretorId = document['corretorId'];

    // permite apenas o corretor dono do local
    if (corretorId != _user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Você não tem permissão para editar este local!')),
      );
      return;
    }

    final _formKey = GlobalKey<FormState>();
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
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Núm. da rua",
                      icon: Icon(Icons.edit_road),
                    ),
                    controller: _controladorNumero,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informação exigida!';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Prédio",
                      icon: Icon(Icons.apartment),
                    ),
                    controller: _controladorPredio,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Núm. do apartamento",
                      icon: Icon(Icons.numbers),
                    ),
                    controller: _controladorApartamento,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Observação",
                      icon: Icon(Icons.lightbulb),
                    ),
                    controller: _controladorObs,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
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
                if (_formKey.currentState!.validate()) {
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
                }
              },
            ),
          ],
        );
      },
    );
  }

  confirmationAlert(BuildContext context, String idLocal) async {
    // captura o local pelo id
    DocumentSnapshot document = await _locais.doc(idLocal).get();
    final String corretorId = document['corretorId'];

    // permite apenas o corretor dono do local
    if (corretorId != _user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Você não tem permissão para excluir este local!')),
      );
      return;
    }

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
