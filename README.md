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
- [Refactorizacion SOLID] (#refactorizacion-solid)
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
Domain (contratos: repositorios, resolvers de rol)
   │  implementados por
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
- **`domain/`** — contratos e implementaciones que desacoplan a los
  controllers de Firebase y de detalles concretos:
  - `PersonalRepository` (`reservar` / `liberar`), implementado por
    `ConductoresRepository` y `ParamedicosRepository`.
  - `RoleResolver` (`resolve`), implementado por
    `RolesCollectionResolver`, `UsuariosCollectionResolver`,
    `AmbulanciasCollectionResolver` y `AdminsCollectionResolver`.

La asignación de personal (conductor/paramédico) a una ambulancia usa
transacciones de Firestore (`reservarPersonal` en `FirestoreService`) para
evitar que dos alertas reserven al mismo conductor simultáneamente.

## refactorizacion-solid

A partir del MVP inicial se refactorizó el código para reducir la duplicación entre conductores/paramédicos, sacar lógica de negocio de la UI y desacoplar los controllers de Firebase. El comportamiento funcional de la app tuvo cambiós solo se reorganizo el código.

### S — Responsabilidad única (SRP) Diagnostico 3,5

- La pantalla `ambulancia_mapa_screen.dart` ya no maneja `Timer`,
  transacciones ni orquesta tres controllers a la vez. Esa lógica se
  extrajo al nuevo `AtencionAlertaController`, y la pantalla quedó
  limitada a construir la UI y escuchar sus cambios de estado.

- Antes `FirestoreService` los métodos `reservarPersonal` y `liberarPersonal` incluyen lógica de negocio referente a disponibilidad del personal.

- Ahora, se definio la abstracción `PersonalRepository`que se implenta en `ConductoresRepository` y `ParamedicosRepository` cada una encapsulando su propia colección de Firestore y su transacción de reserva y liberación, `PersonalController` paso a depender de la abstracción PersonalRepository en lugar de Firestore directamente.


### O — Abierto/cerrado (OCP) Diagnostico 2
- Antes, agregar una nueva fuente de rol (por ejemplo, una colección
  `voluntarios`) implicaba modificar el método `getUserRole` de
  `AuthService`, añadiendo un nuevo `if`.
- Ahora `AuthService` recibe una `List<RoleResolver>` y las recorre en
  orden. Agregar un nuevo tipo de rol solo requiere **crear una nueva
  clase** que implemente `RoleResolver`, sin tocar código existente.

### D — Inversión de dependencias (DIP) Diagnostico 1,4,6
- Antes, `MapController` instanciaba directamente `MapsService()` y
  `LocationService()`, dependiendo directamente de las clases.
   - Ahora `MapController` recibe `IMapsService` e `ILocationService` por
  constructor, y `AuthService` recibe `FirebaseAuth`,
  `FirebaseFirestore` y la lista de `RoleResolver` por constructor lo que
  además habilita pruebas unitarias con dobles de prueba.

   `AuthService` instanciaba directamente `FirebaseAuth.instance` y `FirebaseFirestore.instance`  Impidiendo hacer pruebas unitarias a AuthServices sin conectarse a Firebase, además,  en caso de cambiar de proveedor de servicio `AuthService` debería reescribirse 

- Antes `AmbulanciaController` contruia `FirebaseFirestore.instance` en el método `asignarPersonalAtomico` y  `liberarpersonalYResetAmbulancia` directamente esa     responsabilidad pasó a `FirestoreService`, que es quien conoce el modelo de datos.
  Ahora `AmbulanciaController` recibe una abstracción de repositorio en vez de una implementación concreta evitando que un cambio de base de datos a futuro oblique a modificar el controlador



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
de errores de red exhaustivo previstos para entregas posteriores.
