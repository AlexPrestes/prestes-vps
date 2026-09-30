#!/bin/sh
# Uso: check-encrypted.sh <arquivo.enc.*>...
# Falha se algum arquivo não tiver os metadados do sops ou tiver valor fora de ENC[...].
set -eu
status=0

fail() {
  echo "$1: $2" >&2
  status=1
}

for f in "$@"; do
  case "$f" in
  *.env)
    grep -q '^sops_mac=ENC\[' "$f" || fail "$f" "sem metadados do sops"
    bad=$(grep -vnE '^(#|$|sops_)' "$f" | grep -vE '^[0-9]+:[A-Za-z_][A-Za-z0-9_]*=ENC\[' || true)
    ;;
  *.yaml | *.yml)
    grep -q '^    mac: ENC\[' "$f" || fail "$f" "sem metadados do sops"
    # Antes do bloco "sops:", toda linha é chave sem valor (mapa) ou valor ENC[...].
    bad=$(sed '/^sops:/,$d' "$f" | grep -nvE '^[[:space:]]*(#|$)' | grep -vE 'ENC\[|:[[:space:]]*$' || true)
    ;;
  *)
    fail "$f" "formato não suportado"
    continue
    ;;
  esac
  [ -z "$bad" ] || fail "$f" "valor em texto puro na(s) linha(s) $(echo "$bad" | cut -d: -f1 | tr '\n' ' ')"
done

exit "$status"
