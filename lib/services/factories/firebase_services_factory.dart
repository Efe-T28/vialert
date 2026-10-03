import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import '../firestore_service.dart';
import '../location_service.dart';
import '../maps_service.dart';
import '../i_auth_service.dart';
import '../i_database_service.dart';
import '../i_location_service.dart';
import '../i_maps_service.dart';
import 'app_services_factory.dart';

/// Familia de producción: Firebase + Geolocator + Google Directions.
class FirebaseServicesFactory extends AppServicesFactory {
  @override
  IAuthService createAuthService() => AuthService(
        auth: FirebaseAuth.instance,
        db: FirebaseFirestore.instance,
      );

  @override
  IDatabaseService createDatabaseService() => FirestoreService();

  @override
  ILocationService createLocationService() => LocationService();

  @override
  IMapsService createMapsService() => MapsService();
}