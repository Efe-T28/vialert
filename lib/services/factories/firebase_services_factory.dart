import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_auth_adapter.dart';
import '../firestore_service.dart';
import '../location_service.dart';
import '../google_directions_adapter.dart';
import '../directions/directions_api_client.dart';
import '../i_auth_service.dart';
import '../i_database_service.dart';
import '../i_location_service.dart';
import '../i_maps_service.dart';
import 'app_services_factory.dart';

/// Familia de producción: Firebase + Geolocator + Google Directions.
class FirebaseServicesFactory extends AppServicesFactory {
  @override
  IAuthService createAuthService() => FirebaseAuthAdapter(
        auth: FirebaseAuth.instance,
        db: FirebaseFirestore.instance,
      );

  @override
  IDatabaseService createDatabaseService() => FirestoreService();

  @override
  ILocationService createLocationService() => LocationService();

   static const String _mapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  @override
  IMapsService createMapsService() =>
  GoogleDirectionsAdapter(DirectionsApiClient(apiKey: _mapsApiKey));
}