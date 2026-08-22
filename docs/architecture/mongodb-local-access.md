# Acceso local a MongoDB

MongoDB pertenece exclusivamente a `public-api` y mantiene autenticacion
habilitada. En Docker, `public-api` usa el servicio `mongodb` y autentica el
usuario root contra la base `admin`:

```text
mongodb://ferreplus:<MONGO_ROOT_PASSWORD>@mongodb:27017/ferreplus_public?authSource=admin
```

Desde DataGrip en el host se usa el bind loopback publicado por Compose:

```text
mongodb://ferreplus:<MONGO_ROOT_PASSWORD>@127.0.0.1:27017/ferreplus_public?authSource=admin
```

En DataGrip seleccionar autenticacion **User & Password** y establecer
**Authentication database: `admin`**. Nunca se debe copiar una password real a
esta documentacion, al repositorio o a logs.

El volumen `mongodb_data` conserva las credenciales creadas durante la primera
inicializacion. Si la password del archivo `.env` no coincide con esa
inicializacion, se debe corregir el secreto local o ejecutar una rotacion
revisada por el operador; no se debe borrar el volumen ni deshabilitar
MongoDB auth.

El error DataGrip `code 18` con `source/authSource=ferreplus_public` ocurre
porque el usuario root fue creado en `admin`. Omitir `authSource=admin` hace
que MongoDB busque `ferreplus` en la base equivocada. Valores operativos:
host `127.0.0.1`, port `27017`, user `ferreplus`, database
`ferreplus_public`, authentication database `admin` y password del `.env`
ignorado. Una URI sin credenciales no funciona.

Verificacion autenticada sin imprimir la password:

```bash
mongosh 'mongodb://ferreplus@127.0.0.1:27017/ferreplus_public?authSource=admin' \
  --password --eval 'db.runCommand({ping: 1})'
```
