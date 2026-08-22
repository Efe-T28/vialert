# Vialert

Aplicación móvil (Flutter) para la gestión de alertas viales y despacho de
ambulancias en tiempo real. Un ciudadano reporta una emergencia con su
ubicación en el mapa, un administrador asigna una ambulancia disponible
(conductor + paramédico), y la tripulación recibe y atiende la alerta hasta
marcarla como resuelta.

> Entrega: Implementación MVP — proyecto compilable, con arquitectura por
> capas (modelos, servicios, controladores, UI) y funcionalidades principales
> operativas sobre Firebase.

## Contenido

- [Funcionalidades del MVP](#funcionalidades-del-mvp)
- [Roles de usuario](#roles-de-usuario)
- [Arquitectura del proyecto](#arquitectura-del-proyecto)
- [Stack técnico](#stack-técnico)
- [Requisitos previos](#requisitos-previos)
- [Configuración del proyecto](#configuración-del-proyecto)
- [Ejecución](#ejecución)
- [Estructura de carpetas](#estructura-de-carpetas)

## Funcionalidades del MVP

1. **Registro e inicio de sesión** de ciudadanos, con autenticación por
   correo y contraseña (Firebase Auth) y creación automática del perfil en
   Firestore.
2. **Creación de alertas** con tipo, descripción y ubicación tomada del GPS
   del dispositivo o seleccionada en el mapa.
3. **Panel de administrador** para dar de alta ambulancias, conductores y
   paramédicos, y asignar una ambulancia disponible a una alerta activa.
4. **Seguimiento de alerta en mapa** para la tripulación de ambulancia
   (ubicación de la emergencia, ruta sugerida) y cambio de estado de la
   alerta (`activa` → `en proceso` → `atendida`).
5. **Historial de alertas** por ciudadano (sus propios reportes) y por
   ambulancia (emergencias atendidas).

## Roles de usuario

| Rol | Puede hacer |
|---|---|
| `usuario` | Crear alertas, ver su ubicación en el mapa, consultar su historial de alertas |
| `admin` | Registrar ambulancias/conductores/paramédicos, asignar ambulancias a alertas |
| `ambulancia` | Ver alertas asignadas, trazar ruta, marcar alerta como atendida |

El rol se resuelve en `AuthWrapper` (`lib/ui/app.dart`) tras el login y
determina la pantalla de inicio (`UsuarioHome`, `AdminHome` o
`AmbulanciaHome`).

## Arquitectura del proyecto

El código sigue una separación por capas típica de una app cliente sobre un
backend serverless (Firebase):

```
UI (widgets/screens)
   │  consume y notifica
   ▼
Controllers (ChangeNotifier / estado de la app)
   │  delega operaciones de datos
   ▼
Services (Auth, Firestore, ubicación, rutas)
   │
   ▼
Firebase (Auth + Firestore) / Google Maps / Geolocator
```

- **`models/`** — clases de dominio puras (`AlertaModel`, `AmbulanciaModel`,
  `ConductorModel`, `ParamedicoModel`, `UsuarioModel`, `UbicacionModel`), cada
  una con `toMap()` / `fromMap()` para (de)serializar contra Firestore.
- **`services/`** — acceso a fuentes externas: `AuthService` (Firebase Auth),
  `FirestoreService` (CRUD y streams de las colecciones), `LocationService`
  (permisos y ubicación del dispositivo vía `geolocator`), `MapsService`
  (rutas vía Google Directions API).
- **`controllers/`** — estado de la aplicación (`ChangeNotifier` +
  `provider`): `AuthController`, `AlertController`, `PersonalController`,
  `AmbulanciaController`, `MapController`. Median entre la UI y los
  servicios; no acceden a Firebase directamente.
- **`ui/`** — pantallas agrupadas por rol (`admin/`, `ambulancia/`,
  `usuario/`, `auth/`), más `app.dart` con el enrutamiento por rol.

La asignación de personal (conductor/paramédico) a una ambulancia usa
transacciones de Firestore (`reservarPersonal` en `FirestoreService`) para
evitar que dos alertas reserven al mismo conductor simultáneamente.

## Stack técnico

- **Flutter / Dart** (SDK `>=3.5.0 <4.0.0`)
- **Firebase**: Auth (correo/contraseña) y Cloud Firestore (base de datos en
  tiempo real)
- **Google Maps SDK** + **Directions API** para mapa y trazado de rutas
- **Geolocator** para ubicación del dispositivo
- **Provider** para gestión de estado

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y
  configurado (`flutter doctor` sin errores bloqueantes)
- Una cuenta de [Firebase](https://console.firebase.google.com/) con un
  proyecto creado (Auth con proveedor "Correo/contraseña" habilitado, y
  Cloud Firestore en modo de prueba o con reglas propias)
- Una clave de [Google Maps SDK for Android](https://console.cloud.google.com/google/maps-apis)
  habilitada para tu proyecto
- Android Studio o VS Code con los plugins de Flutter/Dart

## Configuración del proyecto

Este repositorio **no incluye claves ni credenciales reales** — cada archivo
sensible tiene una plantilla `*.example` que debes copiar y completar con
tus propios valores antes de compilar.

1. Clona el repositorio e instala las dependencias:
   ```bash
   git clone <url-del-repositorio>
   cd vialert
   flutter pub get
   ```

2. **Firebase**: crea un proyecto en Firebase, agrega una app Android con el
   `applicationId` `com.example.vialert` (o el que definas en
   `android/app/build.gradle.kts`), y:
   - Descarga tu propio `google-services.json` y colócalo en
     `android/app/google-services.json` (usa
     `android/app/google-services.json.example` como referencia de formato).
   - Genera tu propio `lib/firebase_options.dart` con la CLI de FlutterFire:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
     o complétalo manualmente a partir de
     `lib/firebase_options.dart.example`.

3. **Claves de mapas**: copia `android/local.properties.example` como
   `android/local.properties` y completa:
   ```properties
   sdk.dir=/ruta/a/tu/Android/Sdk
   flutter.sdk=/ruta/a/tu/flutter
   MAPS_API_KEY=tu_clave_de_google_maps
   MAPBOX_ACCESS_TOKEN=tu_access_token_de_mapbox
   ```
   `MAPS_API_KEY` se inyecta automáticamente en el `AndroidManifest.xml` vía
   `manifestPlaceholders` (ver `android/app/build.gradle.kts`); no se edita
   el manifest directamente.

4. Habilita en Firestore las colecciones que usa la app (se crean solas al
   primer escritura, pero conviene definir reglas de seguridad antes de
   producción): `usuarios`, `admins`, `ambulancias`, `alertas`, `roles`,
   `personal/conductores/items`, `personal/paramedicos/items`.

## Ejecución

```bash
flutter pub get
flutter run
```

Para compilar un APK de depuración:

```bash
flutter build apk --debug
```

## Estructura de carpetas

```
lib/
├── main.dart                  # Punto de entrada, inicializa Firebase y providers
├── firebase_options.dart      # Config de Firebase (no versionado, ver .example)
├── controllers/                # Estado de la app (ChangeNotifier)
├── models/                     # Entidades de dominio
├── services/                   # Acceso a Firebase, GPS y rutas
└── ui/
    ├── admin/                  # Pantallas del administrador
    ├── ambulancia/              # Pantallas de la tripulación
    ├── usuario/                 # Pantallas del ciudadano
    ├── auth/                    # Login y registro
    └── app.dart                 # Enrutamiento por rol
```

## Estado del proyecto

Este es el entregable correspondiente al **MVP** del taller: cubre el flujo
principal (reporte de alerta → asignación → atención) de forma funcional
sobre datos reales de Firebase. Quedan fuera de este alcance: pruebas
automatizadas, reglas de seguridad de Firestore para producción, y manejo
de errores de red exhaustivo — previstos para entregas posteriores.
