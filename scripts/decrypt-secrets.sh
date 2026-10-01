#!/bin/sh
# Uso: decrypt-secrets.sh <pasta do componente> [uid do dono]
# Gera <pasta>/.secrets/<CHAVE> para cada chave do <pasta>/secrets.spec.yaml,
# lendo do secrets.enc.yaml na raiz do repositório. A seção é o nome da pasta;
# chaves com "from: instance.X" vêm da seção instance.
set -eu
dir="${1:?pasta do componente não informada}"
owner="${2:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/secrets.enc.yaml"
spec="$dir/secrets.spec.yaml"
section="$(basename "$dir")"
out="$dir/.secrets"

# Recria do zero: chave removida do manifesto não pode sobrar no disco.
rm -rf "$out"
mkdir -p "$out"
chmod 700 "$out"

grep -E '^[A-Za-z0-9_]+:' "$spec" | while IFS= read -r line; do
  key="${line%%:*}"
  from="$(printf '%s' "$line" | sed -n 's/.*from: *instance\.\([A-Za-z0-9_]*\).*/\1/p')"
  if [ -n "$from" ]; then
    path="[\"instance\"][\"$from\"]"
  else
    path="[\"$section\"][\"$key\"]"
  fi
  sops -d --extract "$path" "$src" >"$out/$key"
  chmod 600 "$out/$key"
  if [ -n "$owner" ]; then chown "$owner" "$out/$key"; fi
done
