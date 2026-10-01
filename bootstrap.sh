#!/bin/sh
# Sobe ou atualiza a instância inteira a partir deste repositório.
# 1. scripts/init: garante chaves e segredos (pergunta só o que faltar)
# 2. confere que os segredos estão commitados e no GitHub (o Komodo lê de lá)
# 3. playbooks: bootstrap (como root se o admin ainda não existe), komodo, backup
set -eu
root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

scripts/init

git rev-parse '@{upstream}' >/dev/null 2>&1 || {
  echo "A branch atual não tem upstream no GitHub (git push -u origin <branch>)." >&2
  exit 1
}
pending="$(git status --porcelain -- secrets.enc.yaml .sops.yaml)"
unpushed="$(git log --oneline '@{upstream}..HEAD' -- secrets.enc.yaml .sops.yaml)"
if [ -n "$pending$unpushed" ]; then
  echo "secrets.enc.yaml/.sops.yaml têm mudanças fora do GitHub. Faça commit e push antes." >&2
  exit 1
fi

cd ansible
ansible-galaxy collection install -r requirements.yml >/dev/null

reachable() { ansible prestes-vps -m ansible.builtin.ping -o "$@" >/dev/null 2>&1; }
if reachable; then
  first=""
elif reachable -e ansible_user=root; then
  echo "Admin ainda não existe: bootstrap como root."
  first="-e ansible_user=root"
else
  echo "Sem conexão SSH com a VPS, nem como admin nem como root." >&2
  echo "VPS reinstalada? Remova a chave antiga do host: ssh-keygen -R <host>" >&2
  exit 1
fi

# shellcheck disable=SC2086 # $first é vazio ou dois argumentos
ansible-playbook bootstrap.yml $first
ansible-playbook komodo.yml
ansible-playbook backup.yml

cat <<'EOF'

Instância no ar. Passos ainda manuais (PROJETO.md, seção 8):
- Resource Sync no Komodo (repo, branch main, resource path komodo/resources)
- webhook do GitHub para o procedure deploy-on-push
- layout do Garage
EOF
