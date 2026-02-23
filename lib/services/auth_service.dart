import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? currentUser;
  String? userRole;
  String? userName;   // ← nuevo campo
  bool isLoading = true;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    currentUser = user;
    if (user != null) {
      await _fetchUserData(user.uid);
    } else {
      userRole = null;
      userName = null;
    }
    isLoading = false;
    notifyListeners();
  }

  // Ahora obtenemos rol Y nombre al mismo tiempo
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        userRole = doc.data()?['rol'] ?? 'alumno';
        userName = doc.data()?['nombre'] ?? 'Usuario';
      }
    } catch (e) {
      userRole = null;
      userName = null;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe una cuenta con ese correo';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'El correo no tiene un formato válido';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos';
        default:
          return 'Error al iniciar sesión. Intenta de nuevo';
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
