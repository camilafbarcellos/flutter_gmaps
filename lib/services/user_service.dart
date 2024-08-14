import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  getUser() async {
    return await _users.doc(_currentUser.uid).get();
  }
}
