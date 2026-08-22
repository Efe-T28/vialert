import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vialert/firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/alert_controller.dart';
import 'controllers/personal_controller.dart';
import 'controllers/ambulancia_controller.dart';
import 'controllers/map_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProvider<AuthController>(
            create: (ctx) => AuthController(
                  authService: ctx.read<AuthService>(),
                  firestoreService: ctx.read<FirestoreService>(),
                )),
        ChangeNotifierProvider<AlertController>(
            create: (ctx) => AlertController(ctx.read<FirestoreService>())),
        ChangeNotifierProvider<PersonalController>(
            create: (ctx) => PersonalController(ctx.read<FirestoreService>())),
        ChangeNotifierProvider<AmbulanciaController>(
            create: (ctx) =>
                AmbulanciaController(ctx.read<FirestoreService>())),
        ChangeNotifierProvider<MapController>(create: (_) => MapController()),
      ],
      child: const MyApp(),
    ),
  );
}
