import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google sign in
  signInWithGoogle() async {
    if (kIsWeb) {
      //WEB
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        // pop-up de login Google para receber a credencial (dados) do usuário
        return await _auth.signInWithPopup(authProvider);
      } catch (e) {
        print(e);
      }
    } else {
      //ANDROID
      // página de login da conta Google
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      // verifica se a conta Google foi logada (!= de null) e recupera a autenticação
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // cria uma credencial com a autenticação obtida
        final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken);

        try {
          // a partir da credencial criada, recupera os dados do usuário
          return await _auth.signInWithCredential(credential);
        } catch (e) {
          print(e);
        }
      }
    }
  }
}
