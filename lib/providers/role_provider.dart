import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userRole;
  String? get userRole => _userRole;

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _userRole = userDoc['role'];
          notifyListeners();
        }
      } catch (e) {
        print('Error checking user role: $e');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = null;
    notifyListeners();
  }
}
