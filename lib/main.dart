import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vialert/firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/alert_controller.dart';
import 'controllers/personal_controller.dart';
import 'controllers/ambulancia_controller.dart';
import 'controllers/map_controller.dart';
import 'controllers/atencion_alerta_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'services/i_auth_service.dart';
import 'services/i_database_service.dart';
import 'domain/repositories/conductores_repository.dart';
import 'domain/repositories/paramedicos_repository.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<IAuthService>(
            create: (_) => AuthService(
                  auth: FirebaseAuth.instance,
                  db: FirebaseFirestore.instance,
                )),
        Provider<IDatabaseService>(create: (_) => FirestoreService()),
        Provider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProvider<AuthController>(
            create: (ctx) => AuthController(
                  authService: ctx.read<IAuthService>(),
                  firestoreService: ctx.read<IDatabaseService>(),
                )),
        ChangeNotifierProvider<AlertController>(
            create: (ctx) => AlertController(ctx.read<IDatabaseService>())),
        ChangeNotifierProvider<PersonalController>(
            create: (ctx) => PersonalController(
                  ctx.read<IDatabaseService>(),
                  ConductoresRepository(FirebaseFirestore.instance),
                  ParamedicosRepository(FirebaseFirestore.instance),
                )),
        ChangeNotifierProvider<AmbulanciaController>(
            create: (ctx) =>
                AmbulanciaController(ctx.read<IDatabaseService>())),
        ChangeNotifierProvider<MapController>(
            create: (ctx) =>
                MapController(locationService: ctx.read<LocationService>())),
        ChangeNotifierProvider<AtencionAlertaController>(
            create: (ctx) => AtencionAlertaController(
                  ctx.read<AlertController>(),
                  ctx.read<AmbulanciaController>(),
                  ctx.read<MapController>(),
                )),
      ],
      child: const MyApp(),
    ),
  );
}