#!/bin/sh
# Aplica a senha do akadmin a partir de /run/secrets/AKADMIN_PASSWORD.
# Espera o Authentik terminar de inicializar (até 5 minutos).
set -eu
container="authentik-worker-1"
code="from authentik.core.models import User
u = User.objects.get(username='akadmin')
p = open('/run/secrets/AKADMIN_PASSWORD').read().strip()
if not u.check_password(p):
    u.set_password(p)
    u.save()
print('akadmin-ok')"

i=0
until docker exec "$container" ak shell -c "$code" 2>/dev/null | grep -q akadmin-ok; do
  i=$((i + 1))
  if [ "$i" -ge 30 ]; then
    echo "Authentik não ficou pronto a tempo" >&2
    exit 1
  fi
  sleep 10
done
echo "Senha do akadmin aplicada a partir de /run/secrets"
