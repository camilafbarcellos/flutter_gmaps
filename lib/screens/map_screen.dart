import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/services/user_service.dart';
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
  final _user = UserService().getUser();
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
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
      return;
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      return;
    }

    // captura a localização atual do usuário
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    // capturar endereço
    Address currentAddress = await geoCoder.getAddressFromLatLng(
        latitude: currentLatLng.latitude, longitude: currentLatLng.longitude);

    // atualiza a posição da câmera para a localização atual
    _posicaoCamera = CameraPosition(target: currentLatLng, zoom: 15);
    _movimentarCamera();

    // Adiciona um marcador na localização atual
    Marker currentLocationMarker = Marker(
      markerId: MarkerId('currentLocation'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      position: currentLatLng,
      onTap: () => {
        // zoom na localização atual
        _posicaoCamera = CameraPosition(target: currentLatLng, zoom: 17),
        _movimentarCamera()
      },
      infoWindow: InfoWindow(
        title: 'Sua localização atual',
        snippet: '${currentAddress.addressDetails.road} ' +
            '- ${currentAddress.addressDetails.neighbourhood}, ' +
            '${currentAddress.addressDetails.postcode}',
      ),
    );
    setState(() {
      _marcadores.add(currentLocationMarker);
    });
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
    String pais = address.addressDetails.country;
    String cep = address.addressDetails.postcode;

    // infos do corretor
    String? corretor = _user.displayName;
    String? corretorId = _user.uid;

    // criar marcador
    Marker marcador = Marker(
      markerId: MarkerId("marcador-${latLng.latitude}=${latLng.longitude}"),
      position: latLng,
      infoWindow: InfoWindow(
        title: '$rua, $bairro, $cidade - $estado, $cep',
        snippet:
            'Prezado (a) $corretor, acesse a lista para editar o seu marcador!',
      ),
    );
    setState(() {
      _marcadores.add(marcador);
    });

    // gravar no Firestore
    Map<String, dynamic> local = Map();
    local['corretor'] = corretor;
    local['corretorId'] = corretorId;
    local['rua'] = rua;
    local['numero'] = numero;
    local['bairro'] = bairro;
    local['cidade'] = cidade;
    local['estado'] = estado;
    local['pais'] = pais;
    local['cep'] = cep;
    local['observacao'] = '';
    local['predio'] = '';
    local['apartamento'] = '';
    local['latitude'] = latLng.latitude;
    local['longitude'] = latLng.longitude;
    _locais.add(local);
  }

  // Carrega marcadores a partir do Firestore
  carregarMarcadores() async {
    QuerySnapshot snapshot = await _locais.get();
    List<DocumentSnapshot> locais = snapshot.docs;

    Set<Marker> marcadoresTemp = {};

    for (var doc in locais) {
      LatLng latLng = LatLng(doc.get('latitude'), doc.get('longitude'));
      String title;
      String snippet;
      // pegar infos
      String corretor = doc.get('corretor');
      String predio = doc.get('predio');
      String apartamento = doc.get('apartamento');
      String rua = doc.get('rua');
      String numero = doc.get('numero');
      String bairro = doc.get('bairro');
      String cidade = doc.get('cidade');
      String estado = doc.get('estado');
      String cep = doc.get('cep');
      String observacao = doc.get('observacao');

      if (predio.isEmpty) {
        title = '$rua, $numero';
        snippet = '$bairro, $cidade - $estado, $cep';
      } else {
        title = '$predio, apto. N.º $apartamento';
        snippet = '$rua, $numero - $bairro, $cidade - $estado, $cep';
        if (observacao.isNotEmpty) {
          snippet += '\nObs.: $observacao';
        }
      }
      snippet += '\nCorretor: $corretor';

      Marker marcador = Marker(
        markerId: MarkerId(doc.id),
        position: latLng,
        onTap: () => {
          // zoom na localização do marcador
          _posicaoCamera = CameraPosition(target: latLng, zoom: 17),
          _movimentarCamera()
        },
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
      );
      marcadoresTemp.add(marcador);
    }

    setState(() {
      _marcadores = marcadoresTemp;
    });
  }

  // método para mostrar o local gravado no Firestore
  mostrarLocal(String? idLocal) async {
    // captura documento com base no id e cria um objeto LatLong
    DocumentSnapshot local = await _locais.doc(idLocal).get();
    LatLng latLng = LatLng(local.get('latitude'), local.get('longitude'));
    // posiciona a câmera e movimenta para a posição
    _posicaoCamera = CameraPosition(target: latLng, zoom: 17);
    _movimentarCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/logos/googlemaps-white.png',
          width: 175,
        ),
        centerTitle: true,
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
        myLocationButtonEnabled: true,
        compassEnabled: true,
        onLongPress: _addMarcador,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // carrega os marcadores e a localização atual
    carregarMarcadores();
    // caso tenha identificação de local, mostra ele,
    if (widget.idLocal != null) {
      mostrarLocal(widget.idLocal);
    } else {
      // senao, mostra a localização atual
      getLocation();
    }
  }
}
