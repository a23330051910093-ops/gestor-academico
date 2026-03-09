import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? currentUser;
  String? userRole;
  String? userName;
  String? alumnoIdHijo; // ← agregar junto a los otros campos
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

  Future<void> _fetchUserData(String uid) async {
    try {
      // Primero busca en la colección usuarios (docente)
      final docUsuario = await _db.collection('usuarios').doc(uid).get();
      if (docUsuario.exists) {
        userRole = docUsuario.data()?['rol'] ?? 'alumno';
        userName = docUsuario.data()?['nombre'] ?? 'Usuario';
        return;
      }

      // Si no está en usuarios, busca en alumnos por uid
      final queryAlumno = await _db
          .collection('alumnos')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (queryAlumno.docs.isNotEmpty) {
        userRole = 'alumno';
        userName = queryAlumno.docs.first.data()['nombre'] ?? 'Alumno';
        return;
      }

      // Si no está en alumnos, busca como tutor
      final queryTutor = await _db
          .collection('alumnos')
          .where('uidTutor', isEqualTo: uid)
          .limit(1)
          .get();
      if (queryTutor.docs.isNotEmpty) {
        userRole = 'padre';
        userName = 'Padre/Tutor';
        alumnoIdHijo = queryTutor.docs.first.id;
        return;
      }

      // Si no se encuentra en ninguna colección
      userRole = null;
      userName = null;
    } catch (e) {
      userRole = null;
      userName = null;
    }
  }

  // Login normal
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

  // ─── Activar cuenta de alumno ─────────────────────────────
  // Verifica que la matrícula exista y que no tenga cuenta aún
  Future<Map<String, dynamic>?> buscarAlumnoPorMatricula(
      String matricula) async {
    try {
      final query = await _db
          .collection('alumnos')
          .where('matricula', isEqualTo: matricula.trim())
          .where('cuentaActivada', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return {
        'id': query.docs.first.id,
        'data': query.docs.first.data(),
      };
    } catch (e) {
      return null;
    }
  }

  // Crea la cuenta del alumno y la vincula con su documento
  Future<String?> activarCuentaAlumno({
    required String alumnoDocId,
    required String correo,
    required String password,
  }) async {
    try {
      // Crea la cuenta en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password.trim(),
      );

      // Vincula el UID con el documento del alumno en Firestore
      await _db.collection('alumnos').doc(alumnoDocId).update({
        'uid': credential.user!.uid,
        'cuentaActivada': true,
        'correo': correo.trim(),
      });

      return null; // null = éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Ese correo ya tiene una cuenta registrada';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres';
        case 'invalid-email':
          return 'El correo no tiene un formato válido';
        default:
          return 'Error al crear la cuenta. Intenta de nuevo';
      }
    }
  }

  // ─── Activar cuenta de padre/tutor ───────────────────────
  // Verifica que el correo del tutor exista en algún alumno
  Future<Map<String, dynamic>?> buscarAlumnoPorCorreoTutor(
      String correoTutor) async {
    try {
      final query = await _db
          .collection('alumnos')
          .where('correoTutor', isEqualTo: correoTutor.trim())
          .where('cuentaTutorActivada', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return {
        'id': query.docs.first.id,
        'data': query.docs.first.data(),
      };
    } catch (e) {
      return null;
    }
  }

  // Crea la cuenta del padre y la vincula
  Future<String?> activarCuentaPadre({
    required String alumnoDocId,
    required String correoTutor,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: correoTutor.trim(),
        password: password.trim(),
      );

      await _db.collection('alumnos').doc(alumnoDocId).update({
        'uidTutor': credential.user!.uid,
        'cuentaTutorActivada': true,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Ese correo ya tiene una cuenta registrada';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres';
        case 'invalid-email':
          return 'El correo no tiene un formato válido';
        default:
          return 'Error al crear la cuenta. Intenta de nuevo';
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}