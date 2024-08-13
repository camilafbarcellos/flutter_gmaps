import 'package:flutter/material.dart';
import 'package:flutter_gmaps/screens/map_screen.dart';
import 'package:flutter_gmaps/screens/markers_list_screen.dart';

class NavigationOptions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationOptionsState();
  }
}

class _NavigationOptionsState extends State<NavigationOptions> {
  int paginaAtual = 0;
  PageController? pc;

  @override
  void initState() {
    super.initState();
    pc = PageController(initialPage: paginaAtual);
  }

  setPaginaAtual(pagina) {
    setState(() {
      paginaAtual = pagina;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pc,
        children: [MarkersListScreen(), MapScreen()],
        onPageChanged: setPaginaAtual,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: paginaAtual,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Locais"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
        ],
        onTap: (pagina) {
          pc?.animateToPage(pagina,
              duration: const Duration(milliseconds: 400), curve: Curves.ease);
        },
        backgroundColor: Color(0xff1A3668),
        selectedItemColor: Colors.white,
      ),
    );
  }
}
