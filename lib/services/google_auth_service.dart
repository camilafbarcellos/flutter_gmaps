import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google sign in
  Future<UserCredential?> signInWithGoogle() async {
    UserCredential? userCredential;

    if (kIsWeb) {
      // WEB
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        // Pop-up de login Google para receber a credencial (dados) do usuário
        userCredential = await _auth.signInWithPopup(authProvider);
      } catch (e) {
        print(e);
      }
    } else {
      // ANDROID
      // Página de login da conta Google
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      // Verifica se a conta Google foi logada (!= de null) e recupera a autenticação
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // Cria uma credencial com a autenticação obtida
        final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken);

        try {
          // A partir da credencial criada, recupera os dados do usuário
          userCredential = await _auth.signInWithCredential(credential);
        } catch (e) {
          print(e);
        }
      }
    }

    if (userCredential != null) {
      // Após o login bem-sucedido, salve as informações do usuário no Firestore
      final User user = userCredential.user!;
      final DocumentReference userRef =
          _firestore.collection('users').doc(user.uid);

      // Verifica se o usuário já existe no Firestore
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Cria caso não exista
        await userRef.set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
        });
      }
    }

    return userCredential;
  }
}
