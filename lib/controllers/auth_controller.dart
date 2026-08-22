// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/usuario_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService authService;
  final FirestoreService firestoreService;

  User? firebaseUser;
  UsuarioModel? usuario;
  String? role;
  bool isInitializing = true;

  AuthController({required this.authService, required this.firestoreService}) {
    // Listen to Firebase Auth state changes
    authService.authStateChanges().listen((user) async {
      firebaseUser = user;
      if (user == null) {
        usuario = null;
        role = null;
        isInitializing = false;
        notifyListeners();
        return;
      }

      // Get role and optionally load user model if citizen
      role = await authService.getUserRole(user.uid);
      if (role == 'usuario') {
        usuario = await firestoreService.getUsuarioByUid(user.uid);
      } else {
        usuario = null;
      }

      isInitializing = false;
      notifyListeners();
    });
  }

  bool get isAuthenticated => firebaseUser != null;
  String? get uid => firebaseUser?.uid;

  Future<String?> login(String email, String password) async {
    try {
      await authService.login(email, password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registerUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  }) async {
    try {
      await authService.registerUsuarioNormal(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        telefono: telefono,
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await authService.logout();
  }
}
