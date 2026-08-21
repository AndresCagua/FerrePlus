#!/bin/sh
set -eu

secret_source="${S2S_PRIVATE_KEY_FILE:-/run/secrets/s2s_private_key}"
secret_directory=/run/app-secrets
secret_target="$secret_directory/s2s_private_key"

if [ ! -r "$secret_source" ]; then
    printf '%s\n' 'Required S2S private key secret is unavailable.' >&2
    exit 1
fi

install -d -o appuser -g appuser -m 0700 "$secret_directory"
install -o appuser -g appuser -m 0400 "$secret_source" "$secret_target"

export S2S_PRIVATE_KEY_FILE="$secret_target"
exec runuser -u appuser -- "$@"
