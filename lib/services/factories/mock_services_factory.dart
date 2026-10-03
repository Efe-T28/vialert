import '../mocks/mock_auth_service.dart';
import '../mocks/mock_database_service.dart';
import '../mocks/mock_location_service.dart';
import '../mocks/mock_maps_service.dart';
import '../i_auth_service.dart';
import '../i_database_service.dart';
import '../i_location_service.dart';
import '../i_maps_service.dart';
import 'app_services_factory.dart';

/// Familia de pruebas: todo en memoria, sin red ni Firebase.
class MockServicesFactory extends AppServicesFactory {
  @override
  IAuthService createAuthService() => MockAuthService();

  @override
  IDatabaseService createDatabaseService() => MockDatabaseService();

  @override
  ILocationService createLocationService() => MockLocationService();

  @override
  IMapsService createMapsService() => MockMapsService();
}