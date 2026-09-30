#!/bin/sh
# Uso: decrypt-secrets.sh <pasta do stack> [uid do dono]
set -eu
dir="$1"
owner="${2:-}"
src="$dir/secrets.enc.yaml"
out="$dir/.secrets"

mkdir -p "$out"
chmod 700 "$out"

for key in $(sops -d "$src" | sed -n 's/^\([A-Za-z0-9_]*\):.*/\1/p'); do
  sops -d --extract "[\"$key\"]" "$src" >"$out/$key"
  chmod 600 "$out/$key"
  if [ -n "$owner" ]; then chown "$owner" "$out/$key"; fi
done
