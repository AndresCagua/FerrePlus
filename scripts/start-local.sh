#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly QUICK_TUNNEL_IMAGE="cloudflare/cloudflared:2025.8.1"
readonly PUBLIC_TUNNEL="ferreplus-quick-tunnel"
readonly ADMIN_TUNNEL="ferreplus-quick-tunnel-admin"
readonly -a COMPOSE_SERVICES=(
  traefik
  mongodb
  redis
  minio
  admin-api
  public-api
  public-web
  admin-web
)

HTTP_PORT=""
PUBLIC_URL=""
ADMIN_URL=""

log() {
  printf '[ferreplus] %s\n' "$*"
}

error() {
  printf '[ferreplus] ERROR: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Uso:
  ./scripts/start-local.sh
  ./scripts/start-local.sh --stop

Inicia los servicios locales y dos Quick Tunnels temporales de Cloudflare.
EOF
}

check_dependencies() {
  local dependency

  for dependency in docker curl openssl; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      error "Falta la dependencia requerida: ${dependency}."
      exit 1
    fi
  done

  if ! docker compose version >/dev/null 2>&1; then
    error 'Docker Compose no esta disponible mediante "docker compose".'
    exit 1
  fi
}

ensure_s2s_keys() {
  local private_key_file="${S2S_PRIVATE_KEY_FILE:-${REPO_ROOT}/secrets/s2s-private-key.pem}"
  local public_key_file="${S2S_INITIAL_PUBLIC_KEY_FILE:-${REPO_ROOT}/secrets/s2s-public-key.pem}"

  if [[ -r "$private_key_file" && -r "$public_key_file" ]]; then
    return 0
  fi

  if [[ -e "$private_key_file" || -e "$public_key_file" ]]; then
    error 'Falta una de las claves S2S requeridas; no se sobrescribiran claves existentes.'
    return 1
  fi

  mkdir -p -- "$(dirname -- "$private_key_file")" "$(dirname -- "$public_key_file")"
  umask 077
  log 'Generando las claves S2S locales requeridas por los servicios...'
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$private_key_file" >/dev/null 2>&1
  openssl pkey -in "$private_key_file" -pubout -out "$public_key_file" >/dev/null 2>&1
}

compose() {
  docker compose --project-directory "$REPO_ROOT" "$@"
}

remove_quick_tunnel() {
  local container_name="$1"

  docker rm -f "$container_name" >/dev/null 2>&1 || true
}

stop_local() {
  check_dependencies
  remove_quick_tunnel "$PUBLIC_TUNNEL"
  remove_quick_tunnel "$ADMIN_TUNNEL"
  compose stop "${COMPOSE_SERVICES[@]}"
  log 'Quick Tunnels eliminados y servicios de aplicacion detenidos.'
  log 'No se eliminaron contenedores de bases de datos ni volumenes.'
}

wait_for_container_health() {
  local service="$1"
  local deadline=$((SECONDS + 180))
  local container_id
  local status

  container_id="$(compose ps -q "$service")"
  if [[ -z "$container_id" ]]; then
    error "No se encontro el contenedor del servicio ${service}."
    return 1
  fi

  while (( SECONDS < deadline )); do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
    case "$status" in
      healthy)
        return 0
        ;;
      exited|dead)
        error "El servicio ${service} termino con estado ${status}."
        return 1
        ;;
    esac
    sleep 2
  done

  error "Tiempo agotado esperando salud de ${service} (estado: ${status:-desconocido})."
  return 1
}

wait_for_http() {
  local description="$1"
  local url="$2"
  local host_header="${3:-}"
  local deadline=$((SECONDS + 120))

  while (( SECONDS < deadline )); do
    if [[ -n "$host_header" ]]; then
      if curl --fail --silent --show-error --output /dev/null \
        --connect-timeout 2 --max-time 5 \
        --header "Host: ${host_header}" "$url"; then
        return 0
      fi
    elif curl --fail --silent --show-error --output /dev/null \
      --connect-timeout 2 --max-time 5 "$url"; then
      return 0
    fi
    sleep 2
  done

  error "Tiempo agotado esperando ${description}: ${url}"
  return 1
}

extract_tunnel_url() {
  local container_name="$1"

  docker logs "$container_name" 2>&1 \
    | grep -Eo 'https://[[:alnum:]-]+\.trycloudflare\.com' \
    | sort -u \
    | while IFS= read -r url; do
        printf '%s\n' "$url"
        break
      done
}

wait_for_tunnel_url() {
  local container_name="$1"
  local label="$2"
  local deadline=$((SECONDS + 120))
  local url=""

  while (( SECONDS < deadline )); do
    url="$(extract_tunnel_url "$container_name" || true)"
    if [[ "$url" =~ ^https://[[:alnum:]-]+\.trycloudflare\.com$ ]]; then
      printf '%s\n' "$url"
      return 0
    fi
    if ! docker ps --format '{{.Names}}' | grep -Fxq "$container_name"; then
      error "El Quick Tunnel ${label} se detuvo antes de publicar su URL."
      return 1
    fi
    sleep 2
  done

  error "Tiempo agotado esperando la URL del Quick Tunnel ${label}."
  return 1
}

diagnostics() {
  error 'Diagnostico seguro (sin imprimir variables de entorno ni secretos):'
  compose ps || true
  docker inspect --format '{{.Name}} estado={{.State.Status}} salud={{if .State.Health}}{{.State.Health.Status}}{{else}}no-disponible{{end}}' \
    ferreplus-traefik ferreplus-public-api ferreplus-admin-api ferreplus-public-web ferreplus-admin-web 2>/dev/null || true
}

cleanup_on_failure() {
  local exit_code="$1"

  trap - ERR EXIT
  if (( exit_code != 0 )); then
    remove_quick_tunnel "$PUBLIC_TUNNEL"
    remove_quick_tunnel "$ADMIN_TUNNEL"
    diagnostics
  fi
  exit "$exit_code"
}

start() {
  local binding

  trap 'cleanup_on_failure $?' ERR EXIT

  ensure_s2s_keys
  log 'Levantando servicios de aplicacion con Docker Compose...'
  compose up -d --build "${COMPOSE_SERVICES[@]}"

  log 'Esperando salud de Traefik, APIs y portales...'
  wait_for_container_health traefik
  wait_for_container_health admin-api
  wait_for_container_health public-api
  wait_for_container_health public-web
  wait_for_container_health admin-web

  binding="$(compose port traefik 80)"
  HTTP_PORT="${binding##*:}"
  if [[ ! "$HTTP_PORT" =~ ^[0-9]+$ ]]; then
    error "No se pudo determinar el puerto HTTP publicado por Traefik."
    return 1
  fi

  wait_for_http 'el ping de Traefik' "http://127.0.0.1:${HTTP_PORT}/ping"
  wait_for_http 'el portal publico' "http://127.0.0.1:${HTTP_PORT}/health" public.localhost
  wait_for_http 'el portal admin' "http://127.0.0.1:${HTTP_PORT}/health" admin.localhost

  log 'Reemplazando unicamente los Quick Tunnels temporales anteriores...'
  remove_quick_tunnel "$PUBLIC_TUNNEL"
  remove_quick_tunnel "$ADMIN_TUNNEL"
  docker run --detach --network host --restart no --name "$PUBLIC_TUNNEL" \
    "$QUICK_TUNNEL_IMAGE" tunnel --no-autoupdate \
    --url "http://127.0.0.1:${HTTP_PORT}" \
    --http-host-header public.localhost >/dev/null
  docker run --detach --network host --restart no --name "$ADMIN_TUNNEL" \
    "$QUICK_TUNNEL_IMAGE" tunnel --no-autoupdate \
    --url "http://127.0.0.1:${HTTP_PORT}" \
    --http-host-header admin.localhost >/dev/null

  PUBLIC_URL="$(wait_for_tunnel_url "$PUBLIC_TUNNEL" 'publico')"
  ADMIN_URL="$(wait_for_tunnel_url "$ADMIN_TUNNEL" 'admin')"
  wait_for_http 'el Quick Tunnel publico' "$PUBLIC_URL"
  wait_for_http 'el Quick Tunnel admin' "$ADMIN_URL"

  trap - ERR EXIT
  printf '\n'
  log 'Entorno local listo.'
  printf '  Portal publico: %s\n' "$PUBLIC_URL"
  printf '  Portal admin:   %s\n' "$ADMIN_URL"
  printf '\n'
  log 'Para detenerlo de forma segura: ./scripts/start-local.sh --stop'
  log 'Ese comando no elimina volumenes y no toca el named tunnel ferreplus-cloudflared.'
}

main() {
  cd -- "$REPO_ROOT"
  case "${1:-}" in
    '')
      check_dependencies
      start
      ;;
    --stop)
      stop_local
      ;;
    --help|-h)
      usage
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
