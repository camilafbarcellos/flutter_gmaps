import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    // pegar rua
    String rua = address.addressDetails.road;

    // criar marcador
    Marker marcador = Marker(
      markerId: MarkerId("marcador-${latLng.latitude}=${latLng.longitude}"),
      position: latLng,
      infoWindow: InfoWindow(title: rua),
    );
    setState(() {
      _marcadores.add(marcador);
    });

    // gravar no Firestore
    Map<String, dynamic> local = Map();
    local['titulo'] = rua;
    local['latitude'] = latLng.latitude;
    local['longitude'] = latLng.longitude;
    _locais.add(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    // captura o titulo (rua)
    String titulo = local.get('titulo');
    // cria um objeto LatLong com base na lat e long
    LatLng latLng = LatLng(local.get('latitude'), local.get('longitude'));
    // cria um marcador
    setState(() {
      Marker marcador = Marker(
        markerId: MarkerId('marcador=${latLng.latitude}-${latLng.longitude}'),
        position: latLng,
        infoWindow: InfoWindow(title: titulo),
      );
      // adiciona a lista de marcadores
      _marcadores.add(marcador);
      // posiciona a câmera
      _posicaoCamera = CameraPosition(target: latLng, zoom: 15);
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
