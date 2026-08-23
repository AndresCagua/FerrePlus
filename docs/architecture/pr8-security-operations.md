# PR8: seguridad y operacion

## Boundary

`admin-api` es el unico servicio que conoce PostgreSQL y firma las llamadas a
`public-api`. PostgreSQL es una dependencia externa/local existente del host
Linux, accesible desde el contenedor como `host.docker.internal:5432`; Compose
NO crea, inicializa, elimina ni administra esa instancia. `public-api` es el
unico propietario de MongoDB, Redis y MinIO, que si son servicios nuevos de
Compose. Traefik es el unico entrypoint HTTP de las aplicaciones.

La configuracion de `admin-api` conserva `DB_NAME=ferreplus`,
`DB_USERNAME=postgres` y toma `DB_PASSWORD` desde la variable local ignorada
(`POSTGRES_PASSWORD` en `.env`). El servicio usa
`extra_hosts: ["host.docker.internal:host-gateway"]`; no usa el hostname
Compose `postgres` ni depende de un servicio PostgreSQL del archivo.

El contenedor/volumen historico `ferreplus-postgres` / `ferreplus_postgres_data`
se preserva fuera del ciclo de vida declarado por este Compose. No se ejecuta
`compose down -v` ni se realizan operaciones SQL destructivas.

## S2S JWT

Se usa RS256, con `iss=ferreplus-admin-api`, `aud=ferreplus-public-api`,
`sub=admin-api`, `iat`, `jti`, `kid`, `exp` de 120 segundos y scope
`public-api.internal`. La private key se monta solo en `admin-api` como
`S2S_PRIVATE_KEY_FILE`; la public key se monta en `public-api` como
`S2S_INITIAL_PUBLIC_KEY_FILE`. Nunca se agregan esos archivos a Git.

Para rotar: generar un nuevo par fuera del repositorio, publicar la public key
con `POST /api/internal/keys` usando la key vigente, cambiar `S2S_KEY_ID` y la
private key, y mantener la clave anterior durante al menos 10 minutos (TTL del
token mas skew). Retirar despues la clave anterior. El endpoint nunca devuelve
material privado.

## Rate limiting

Redis usa password desde `REDIS_PASSWORD` y solo esta en `public_data`.
Postulaciones: 3/900 s y 10/86400 s por IP; contactos: 5/900 s y 20/86400 s.
El rechazo devuelve 429 y `Retry-After`. Si Redis no esta disponible se usa un
limite local conservador de un intento por minuto y se permite la degradacion
sin bloquear todo el portal. Las rutas internas se excluyen.

## Observabilidad y rollback

Ambas APIs generan/propagan `X-Correlation-ID`; public-api registra eventos HTTP
estructurados con `correlationId` explicito en el JSON, sin tokens, CV, emails,
passwords ni IPs. El `route` usa solo `requestURI` y no registra query strings.
Para rollback, retirar los
routers de talento o volver a la imagen anterior; no borrar volumenes. Si una
rotacion falla, mantener la key anterior y corregir el secreto antes de emitir
tokens con un `kid` desconocido.

El `PublicApiClient` carga la private key RS256 una sola vez al inicializarse y
la conserva en memoria. Para una key montada desde fichero solo consulta
metadata (ruta, `mtime` y tamano) por request; vuelve a parsear el material
unicamente cuando detecta cambio. Para una key inline, el operador debe llamar
`refreshSigningKey()` despues de actualizar el secreto. Cada token conserva el
`kid` configurado, y la rotacion mantiene la public key anterior hasta que
expire el TTL mas el clock skew. Nunca se registra ni se versiona material de
claves.

### Operacion de secretos y Redis

Los secretos deben llegar desde Docker secrets, Vault o el gestor equivalente;
las variables de entorno solo referencian valores proporcionados por runtime.
Redis se conecta con `REDIS_PASSWORD`, sin exponer el password en logs, y solo
la red de datos debe alcanzar Redis. Una alerta de autenticacion o de
disponibilidad de Redis debe activar la degradacion local conservadora descrita
en Rate limiting, no deshabilitar la proteccion.

## Verificacion

```bash
docker compose --env-file .env.example config
docker compose --env-file .env config
mvn -f public-api/pom.xml test
mvn -f admin-api/pom.xml test
cd frontend && npm test && npm run build
git diff --check
git diff -- ':!openspec/**' ':!flutter/**' ':!portal/**' | rg -n -i 'private.key|password|token|secret|BEGIN (RSA )?PRIVATE KEY'  # debe no devolver secretos
```

El entorno requiere crear localmente `secrets/s2s-private-key.pem`,
`secrets/s2s-public-key.pem` y un `.env` ignorado con passwords reales.

El smoke de PostgreSQL debe confirmar que `admin-api` alcanza el PostgreSQL del
host en `host.docker.internal:5432` con las credenciales del `.env`, mientras
`public-api` solo usa MongoDB, Redis y MinIO de Compose. Los hosts
`api-admin.localhost` y `api.localhost` deben responder desde sus respectivas
APIs a traves de Traefik, no desde un router 404.

Si PostgreSQL escucha en el host pero su `pg_hba.conf` solo permite loopback,
el kernel rechazara la conexion proveniente de la red bridge Docker aunque el
puerto este abierto. En ese caso el operador del host debe habilitar de forma
controlada la red Docker para la base `ferreplus` y el usuario `postgres`; este
change NO edita `pg_hba.conf`, no cambia credenciales y no ejecuta SQL.
