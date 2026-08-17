# Convenciones locales de FerrePlus Flutter

## Entorno minimo verificado

- Flutter 3.38.1 (stable) y Dart 3.10.0.
- Android SDK con plataforma 36 y build-tools 35.0.0/36.1.0.
- JDK 21 (`JAVA_HOME` debe apuntar al JDK del entorno antes de ejecutar Gradle).

## Arquitectura

La aplicacion usa Clean Architecture: `presentation/` depende de contratos en
`domain/`, y `data/` implementa esos contratos. Las pantallas se agrupan por
feature; los repositorios no importan widgets ni `material.dart`.

## Nombres y calidad

- Archivos y carpetas en `snake_case`; clases en `PascalCase`.
- Preferir widgets pequenos, inmutables y constructores `const`.
- Estado compartido mediante Riverpod; no usar `setState` para logica de negocio.
- DTOs con `freezed` + `json_serializable`; no editar archivos generados.

## Comandos

Desde `flutter/`, con Java 21 exportado:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

La URL del backend se configura con `--dart-define=API_BASE_URL=...`.
En el emulador Android, el host del equipo es `10.0.2.2`, no `localhost`.

## Commits

El asunto usa `YYYYMMDD`. El cuerpo usa `tipo(scope):` y bullets en espanol.

## Plataformas

Phase 0 genera Android y Web. iOS queda como objetivo secundario y se generara
en un entorno macOS cuando sea necesario.
