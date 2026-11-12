import '../i_auth_service.dart';
import '../i_database_service.dart';
import '../i_location_service.dart';
import '../i_maps_service.dart';
import '../i_notification_service.dart';
import '../i_storage_service.dart';
import '../i_tts_service.dart';

/// Abstract Factory: declara la creación de toda la familia de servicios.
abstract class AppServicesFactory {
  IAuthService createAuthService();
  IDatabaseService createDatabaseService();
  ILocationService createLocationService();
  IMapsService createMapsService();
  IStorageService createStorageService();
  INotificationService createNotificationService();
  ITtsService createTtsService();
}