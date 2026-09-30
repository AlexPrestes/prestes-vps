#!/bin/sh
# Uso: pg-provision.sh <nome> <arquivo com a senha>
# Cria (ou atualiza) usuário e banco <nome> no Postgres compartilhado
set -eu
name="$1"
pass="$(cat "$2")"

case "$name" in
*[!a-z0-9_]* | "") echo "nome inválido: $name" >&2; exit 1 ;;
esac
case "$pass" in
*"
"*) echo "senha com quebra de linha não é suportada" >&2; exit 1 ;;
esac
# Dentro de '...' num comando do psql, \ e ' precisam de escape.
pass="$(printf '%s' "$pass" | sed -e 's/\\/\\\\/g' -e "s/'/''/g")"

{
  printf "\\set name '%s'\n\\set pass '%s'\n" "$name" "$pass"
  cat << 'SQL'
SELECT format('CREATE ROLE %I LOGIN', :'name')
  WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'name')\gexec
SELECT format('ALTER ROLE %I PASSWORD %L', :'name', :'pass')\gexec
SELECT format('CREATE DATABASE %I OWNER %I', :'name', :'name')
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'name')\gexec
SQL
} | docker exec -i postgres-postgres-1 psql -U postgres -v ON_ERROR_STOP=1 -q
