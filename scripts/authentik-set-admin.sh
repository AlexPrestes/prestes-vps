#!/bin/sh
# Aplica a senha do akadmin a partir de /run/secrets/AKADMIN_PASSWORD
# e marca a instalação como concluída (o mesmo que a tela de setup faz).
# Espera o Authentik terminar de inicializar (até 5 minutos).
set -eu
container="authentik-worker-1"
code="from authentik.core.models import User
from authentik.core.apps import Setup
from authentik.blueprints.models import BlueprintInstance
from authentik.flows.models import Flow, FlowAuthenticationRequirement
from authentik.tenants.models import Tenant
p = open('/run/secrets/AKADMIN_PASSWORD').read().strip()
for tenant in Tenant.objects.filter(ready=True):
    with tenant:
        u = User.objects.get(username='akadmin')
        if not u.check_password(p):
            u.set_password(p)
            u.save()
        if not Setup.get(tenant=tenant):
            BlueprintInstance.objects.filter(**{'metadata__labels__blueprints.goauthentik.io/system-oobe': 'true'}).update(enabled=False)
            Flow.objects.filter(slug='initial-setup').update(authentication=FlowAuthenticationRequirement.REQUIRE_SUPERUSER)
            Setup.set(True, tenant=tenant)
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
echo "akadmin configurado e instalação marcada como concluída"
