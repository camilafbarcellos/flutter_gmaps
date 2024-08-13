import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/screens/auth_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding_resolver/geocoding_resolver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  String? idLocal;
  MapScreen({this.idLocal});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _user = FirebaseAuth.instance.currentUser!;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // coleção de locais com marcadores
  final CollectionReference _locais =
      FirebaseFirestore.instance.collection('locais');

  Set<Marker> _marcadores = {};
  GeoCoder geoCoder = GeoCoder();

  static CameraPosition _posicaoCamera =
      CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 15);

  _movimentarCamera() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_posicaoCamera));
  }

  // captura localização atual do usuário
  getLocation() async {
    // testar login de usuário
    print('TESTE USER');
    User? user = await FirebaseAuth.instance.currentUser!;
    if (user != null) print(user!.displayName);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
      return;
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      return;
    } else {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 15);
      _movimentarCamera();
      print("latitude = ${position.latitude}");
      print("longitude = ${position.longitude}");
      //_addMarcador(LatLng(position.latitude, position.longitude)); // marca a posição no mapa
    }
  }

  // captura endereço do marcador e salva no Firestore
  _addMarcador(LatLng latLng) async {
    // capturar endereço
    Address address = await geoCoder.getAddressFromLatLng(
        latitude: latLng.latitude, longitude: latLng.longitude);

    // pegar infos
    String rua = address.addressDetails.road;
    String numero = address.addressDetails.houseNumber;
    String bairro = address.addressDetails.neighbourhood;
    String cidade = address.addressDetails.city;
    String estado = address.addressDetails.state;
    String cep = address.addressDetails.postcode;

    // criar marcador
    Marker marcador = Marker(
      markerId: MarkerId("marcador-${latLng.latitude}=${latLng.longitude}"),
      position: latLng,
      infoWindow: InfoWindow(title: '${rua}, ${numero}'),
    );
    setState(() {
      _marcadores.add(marcador);
    });

    // gravar no Firestore
    Map<String, dynamic> local = Map();
    local['rua'] = rua;
    local['numero'] = numero;
    local['bairro'] = bairro;
    local['cidade'] = cidade;
    local['estado'] = estado;
    local['cep'] = cep;
    local['observacao'] = null;
    local['predio'] = null;
    local['apartamento'] = null;
    local['latitude'] = latLng.latitude;
    local['longitude'] = latLng.longitude;
    _locais.add(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff1A3668),
        iconTheme: IconThemeData(color: Colors.white),
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
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _posicaoCamera,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _marcadores,
        myLocationEnabled: true,
        onLongPress: _addMarcador,
      ),
    );
  }

  // método para mostrar o local gravado no Firestore
  mostrarLocal(String? idLocal) async {
    // captura documento com base no id
    DocumentSnapshot local = await _locais.doc(idLocal).get();
    // captura a rua e numero
    String rua = local.get('rua');
    String numero = local.get('numero');
    // cria um objeto LatLong com base na lat e long
    LatLng latLng = LatLng(local.get('latitude'), local.get('longitude'));
    // cria um marcador
    setState(() {
      Marker marcador = Marker(
        markerId: MarkerId('marcador=${latLng.latitude}-${latLng.longitude}'),
        position: latLng,
        infoWindow: InfoWindow(title: '${rua}, ${numero}'),
      );
      // adiciona a lista de marcadores
      _marcadores.add(marcador);
      // posiciona a câmera
      _posicaoCamera = CameraPosition(target: latLng, zoom: 50);
      // movimenta a câmera para a posição
      _movimentarCamera();
    });
  }

  @override
  void initState() {
    super.initState();
    // caso tenha identificação de local, chama o local, senão pega a localização atual
    if (widget.idLocal != null) {
      mostrarLocal(widget.idLocal);
    } else {
      getLocation();
    }
  }
}
