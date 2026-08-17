# FerrePlus Mobile

Aplicacion Flutter Android/iOS con Clean Architecture, Riverpod, GoRouter y
Material 3. Consume el backend REST existente sin duplicar sus reglas de
negocio.

## Setup y ejecucion

Requiere Flutter 3.38.1, Dart 3.10.0 y JDK 21. Desde este directorio:

```bash
export JAVA_HOME="$HOME/development/jdk-21.0.12+8"
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` apunta al host desde el emulador Android. En un dispositivo fisico
use la IP LAN del equipo, por ejemplo:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
```

## Calidad y builds

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

## Funcionalidades

Login JWT y permisos, dashboard, catalogos, ventas POS, compras, movimientos
de stock, gastos, gestion de precios, usuarios, roles, reportes, logs y chat
IA con fuentes, conversacion continuada y reconstruccion de indice protegida
por permiso. Las respuestas del chat usan un renderer Markdown seguro sin HTML
ejecutable.

## Arquitectura

`lib/domain` contiene modelos, contratos y casos de uso; `lib/data` contiene
DTOs, repositorios y Dio; `lib/presentation` contiene providers y widgets por
feature. La URL nunca se fija en codigo: se entrega mediante
`API_BASE_URL` usando `--dart-define`.
