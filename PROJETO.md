# prestes.cloud — visão do projeto

> Este documento descreve **o que o projeto é, para onde vai e como as peças se conectam**.
> O projeto está sendo construído **em fases**. Muita coisa descrita aqui ainda **não existe
> de propósito**: a seção [Estado atual](#3-estado-atual) diz exatamente o que já está no ar
> e o que está planejado. **Ausência de um componente planejado não é falha de configuração.**
> Antes de "corrigir" algo, confira em qual fase ele está.

---

## 1. Objetivo

Uma **plataforma de dados e machine learning**, rodando numa única VPS, que serve a três
propósitos ao mesmo tempo:

1. **Template completamente automatizado.** O repositório é um **modelo reutilizável**:
   qualquer pessoa pode fazer um fork, fornecer um pequeno conjunto de parâmetros e segredos
   próprios, e obter a plataforma inteira numa VPS vazia **sem passos manuais além do
   bootstrap inicial**. A instância `prestes.cloud` é a **primeira instância** desse template,
   não o objetivo final. Ver [seção 11](#11-o-repositório-como-template).
2. **Portfólio de ML Engineer.** Recrutadores e gestores recebem acesso de visitante e
   conseguem **ver e acompanhar a plataforma funcionando**: pipelines rodando, experimentos,
   modelos, métricas, logs e o histórico de deploys. O foco principal é **observabilidade**:
   ter um lugar onde se acompanha tudo o que é feito. O próprio fato de a plataforma ser um
   template reproduzível também faz parte do portfólio.
3. **Laboratório pessoal.** Um ambiente real que o dono usa, onde pode hospedar projetos
   próprios (incluindo, no futuro, algum SaaS) e convidar pessoas para visitar.

Não é um sistema de produção com clientes. Decisões buscam **boas práticas de mercado com
simplicidade proporcional** a um projeto pessoal.

### O que um visitante deve conseguir ver (visão final)

- A arquitetura explicada numa página de vitrine (`prestes.cloud`).
- Painéis de observabilidade (Grafana): saúde da infraestrutura, execução dos pipelines,
  qualidade dos dados, métricas dos modelos, logs.
- Experimentos e modelos (MLflow), pipelines (Windmill), linhagem dos dados (dbt docs),
  métricas de negócio (Lightdash) e o histórico de deploys (Komodo), tudo em modo leitura.
- Um agente (LangChain) que responde perguntas sobre a própria plataforma
  ("por que o último pipeline falhou?", "qual modelo está em produção?").

---

## 2. Princípios (regras que valem para tudo)

1. **O repositório é a fonte da verdade.** Nada é criado ou alterado manualmente na VPS.
   O host é configurado pelo Ansible; os serviços são implantados pelo Komodo a partir
   deste repositório. O ambiente deve poder ser **reconstruído do zero** a partir do git.
2. **Tudo que é específico de uma instância é parâmetro.** Domínio, nome do repositório,
   usuário admin, e-mail, IP, chaves públicas: nada disso deve ficar fixo no código. Valores
   específicos de `prestes.cloud` que ainda estão fixos são **dívida conhecida** a ser
   parametrizada (ver seção 11), não um padrão a ser copiado em arquivos novos.
3. **Todo passo manual é dívida.** Um passo manual só é aceito temporariamente, documentado
   na seção 8, com um plano para automatizá-lo ou transformá-lo em entrada do bootstrap.
4. **Um único mecanismo de segredos: SOPS + age.**
   - Segredos ficam cifrados num único arquivo no repositório (`secrets.enc.yaml`); cada
     componente declara o que precisa num manifesto (`secrets.spec.yaml`). Ver seção 4.4.
   - Chegam aos containers **como arquivos em `/run/secrets`** (secrets do Docker Compose).
   - Nunca como valor em variável de ambiente, nunca em texto puro no repositório
     (o repositório é **público**), nunca como variável/segredo do Komodo.
   - Hash de senha também é tratado como segredo: não vai para o repositório.
   - Cada instância do template tem **suas próprias chaves age e seus próprios segredos**.
     O `secrets.enc.yaml` commitado só abre com as chaves da instância que o gerou.
5. **Isolamento de rede máximo.** Só o Caddy publica portas na internet. Cada aplicação
   tem redes próprias e não enxerga as outras.
6. **Verificar antes de afirmar.** Comportamento de ferramentas deve ser confirmado na
   documentação oficial ou no código-fonte **da versão em uso**. Sem certeza, não se aplica.
7. **Um passo por vez**, cada um com uma verificação objetiva no final.
8. **Commits** em português, com prefixos `feat:`, `fix:`, `docs:`, `ci:`.

---

## 3. Estado atual

Legenda: ✅ no ar e verificado · 🚧 em andamento · 📋 planejado (ainda não existe) · 🤔 decisão pendente

| Fase | Conteúdo | Status |
|---|---|---|
| 0 | Repositório, SOPS + age, pre-commit com gitleaks, DNS | ✅ |
| 1 | Bootstrap do host com Ansible + Komodo | ✅ |
| 2 | Ciclo GitOps: push → webhook → Komodo → deploy; Caddy + página estática | ✅ |
| 3a | Postgres (pgvector) com segredos via `/run/secrets` | ✅ |
| 3b | Garage (armazenamento S3) | ✅ |
| 3c | Backup diário com restic (local na VPS) | ✅ (cópia externa 📋) |
| 4a | Authentik em `auth.prestes.cloud`, reconstruível do zero | ✅ |
| 4b | Blueprints do Authentik: grupos, 2FA, usuário pessoal | 📋 próxima |
| 4c | Komodo com login via Authentik (OIDC) e exposto em `deploy.prestes.cloud` | 📋 |
| 5 | Observabilidade | 🤔 ferramentas em avaliação |
| 6 | Plataforma de ML: MLflow, Windmill, dbt | 📋 |
| 7 | Primeiro caso de uso de ponta a ponta | 🤔 caso de uso não escolhido |
| 8 | Lightdash | 📋 |
| 9 | Agente LangChain (repositório `agent-api`) | 📋 |
| 10 | Vitrine final e convites a visitantes | 📋 |
| T | Template: parametrização da instância e eliminação dos passos manuais (seção 11) | 🚧 chaves, segredos e usuário admin feitos (4.4) |

### Coisas que parecem incompletas, mas são intencionais agora

- `deploy.prestes.cloud` responde **"Em breve" (403)** para tudo, exceto `/listener/*`
  (webhooks). A interface do Komodo só é acessada por **túnel SSH** até a fase 4c.
- A página `prestes.cloud` é um placeholder ("Em construção") até a fase 10.
- As redes internas `db` (Postgres) e `s3` (Garage) só têm o próprio serviço: os consumidores
  (MLflow etc.) ainda não existem.
- Não há buckets nem chaves no Garage: serão criados quando o MLflow chegar (fase 6).
- O backup existe só na VPS. A cópia externa (notebook, Google Drive, R2…) é futura.
- O GitHub Actions só tem o workflow `segredos` (verifica que todo `*.enc.*` está cifrado).
  A validação de compose/TOML e a execução dos playbooks são futuras (seção 7).
  Não existem os repositórios `agent-api` e `data-platform`.
- Os três procedures com tag `system` no Komodo (backup do banco do Core, atualização
  automática, rotação de chaves) foram criados pelo próprio Komodo e não estão no
  repositório. Por isso o *Delete Unmatched Resources* do sync está **desligado**.

---

## 4. Arquitetura

### 4.1 Visão geral

```
GitHub: AlexPrestes/prestes-vps  (público, fonte da verdade)
│
├── ansible/ ─────────── executado da máquina do dono → configura o host
├── komodo/ ──────────── compose do Komodo + declarações TOML dos recursos
├── stacks/ ──────────── um diretório por aplicação (compose + config + segredos cifrados)
├── scripts/ ─────────── scripts executados pelo Komodo no pré/pós-deploy
└── webhook (push) ────────────────┐
                                    ▼
VPS prestes.cloud  (Debian 13, Hostinger KVM 2: 2 vCPU, 8 GB RAM)
│
├── HOST ─────────────── configurado pelo Ansible
│   ├── usuário admin (instance.admin_user; SSH só por chave; root bloqueado no SSH)
│   ├── ufw: só 22, 80, 443 · fail2ban · atualizações automáticas · swap 2 GB
│   ├── Docker (repositório oficial)
│   ├── sops (/usr/local/bin/sops) + chave age da VPS (/etc/sops/age/keys.txt, 0600)
│   ├── /opt/komodo ────── compose do Komodo (0750) e .secrets/<CHAVE> (0700/0400)
│   └── restic + timer systemd (backup diário 03:30)
│
├── KOMODO ───────────── sobe pelo Ansible (ansible/komodo.yml)
│   ├── Core ─────────── interface/API; decide o que fazer. Porta só em 127.0.0.1:9120
│   ├── MongoDB ──────── banco do Core (rede interna)
│   └── Periphery ────── executa: git clone, pré-deploy, docker compose up, pós-deploy
│                        clones em /etc/komodo/stacks/<nome-do-stack>
│
└── STACKS ───────────── sobem pelo Komodo, a partir de stacks/
    ├── caddy ✅ ─────── única porta pública (80/443), HTTPS automático
    ├── postgres ✅ ──── Postgres 17 + pgvector, compartilhado, redes internas
    ├── garage ✅ ────── S3 compatível, rede interna
    ├── authentik ✅ ─── identidade/SSO em auth.prestes.cloud
    └── (fases futuras: observabilidade, mlflow, windmill, lightdash, agente…)
```

### 4.2 Divisão de responsabilidades

| Camada | Ferramenta | Responsável por |
|---|---|---|
| Host | Ansible | SO, usuários, SSH, firewall, Docker, sops, chave age, Komodo, backup |
| Serviços | Komodo | Implantar e manter os stacks a partir do repositório |
| Entrada | Caddy | TLS, roteamento por subdomínio, bloqueios de rota |
| Identidade | Authentik | Login único (SSO) e grupos de acesso |
| Dados | Postgres, Garage | Bancos relacionais e armazenamento de objetos |
| Backup | restic | Cópia diária cifrada |

O backup roda **no host, não em container**, de propósito: ele não pode depender do Docker
nem do Komodo, que são justamente o que ele protege.

### 4.3 Fluxo de deploy

```
git push
  → GitHub envia webhook para https://deploy.prestes.cloud/listener/github/procedure/<id>/main
  → Caddy repassa só /listener/* para o Komodo Core (rede edge-komodo)
  → Core executa o procedure "deploy-on-push" (komodo/resources/procedures.toml):
       1. Sync        → lê komodo/resources/*.toml e cria/atualiza recursos
       2. Dados       → BatchDeployStack: postgres, garage
       3. Aplicações  → BatchDeployStack: authentik (e futuras apps)
       4. Borda       → BatchDeployStack: caddy
  → Para cada stack, o Periphery: git pull → pre_deploy → compose up → post_deploy
```

A ordem dos estágios existe por causa das redes: o Postgres cria as redes `db-<app>`,
cada aplicação cria sua rede `edge-<app>`, e o Caddy usa as `edge-*` como externas.

`BatchDeployStack` (e não `...IfChanged`) é usado de propósito: o deploy sempre atualiza o
clone e roda `compose up -d`, que não recria containers se nada mudou no compose.

### 4.4 Chaves e segredos

Tudo é criado e mantido por `scripts/init` (rodado pelo `./bootstrap.sh`):

| Peça | Onde | No git? | Conteúdo |
|---|---|---|---|
| `.instance` | raiz | não | nome da instância e o caminho de cada chave (age pessoal, age da VPS, SSH) |
| chaves | onde o `.instance` disser | não | as que o init cria vão para `~/.config/prestes-vps/<instância>/` |
| `secrets.enc.yaml` | raiz | sim, cifrado | seção `instance` (parâmetros compartilhados, ex.: `admin_user`) e uma seção por componente |
| `secrets.spec.yaml` | em cada componente | sim | o que o componente precisa: `generate: N [, charset: hex]`, `ask: true` ou `from: instance.X` |

- A seção de um componente é o nome do diretório do manifesto: `stacks/authentik` → `authentik`,
  `komodo` → `komodo`, `ansible` → `ansible`.
- `scripts/init` cria o que falta (chave, `.sops.yaml`, valor) e **nunca sobrescreve**; chave
  sem manifesto só gera aviso. `scripts/init --check` só verifica.
- Chave pessoal ausente com `secrets.enc.yaml` existente: o init para (restaurar do gerenciador
  de senhas; uma chave nova não abriria os segredos).
- Manifesto com **uma chave por linha**: o lado da VPS lê com `sed` (o Periphery não tem Python).

```
secrets.enc.yaml + stacks/<app>/secrets.spec.yaml
  → pre_deploy: scripts/decrypt-secrets.sh <pasta-do-stack> [uid-do-dono]
       apaga e recria .secrets/, um arquivo por chave do manifesto (0600), dono opcional
  → compose.yaml declara cada arquivo em `secrets:`
  → o container lê em /run/secrets/<CHAVE>
```

- O Periphery descriptografa usando o `sops` do host (montado no container) e a chave age,
  que entra como **secret do Compose** (`/run/secrets/age_key`, com `SOPS_AGE_KEY_FILE`).
- Aplicações que suportam leitura de arquivo usam isso diretamente
  (`POSTGRES_PASSWORD_FILE`, `file://` do Authentik, `*_file` do Garage, `*_FILE` do Komodo).
- `.secrets/` está no `.gitignore`.
- Ansible: `inventory/group_vars/all/main.yml` lê o `.instance` e o `secrets.enc.yaml`
  (lookup do `community.sops`). O Komodo segue o mesmo manifesto, em `/opt/komodo/.secrets/`.
  Cada playbook começa com `check.yml` (`scripts/init --check` em localhost, antes de conectar).

### 4.5 Redes

| Rede | Membros | Tipo | Criada por |
|---|---|---|---|
| `edge-komodo` | Caddy, Komodo Core | bridge | compose do Komodo |
| `edge-authentik` | Caddy, Authentik server | bridge | stack authentik |
| `db-authentik` | Postgres, Authentik server/worker | **internal** | stack postgres |
| `postgres_db` | Postgres | **internal** | stack postgres |
| `garage_s3` | Garage | **internal** | stack garage |
| `komodo_db` | Mongo, Core | **internal** | compose do Komodo |
| `*_default` | por stack, com saída para a internet | bridge | cada stack |

Regras:

- Só o Caddy publica portas no host. Nenhum outro `ports:` além de `127.0.0.1:` para admin.
  (Portas publicadas pelo Docker ignoram o ufw.)
- Uma rede `edge-<app>` por aplicação: aplicações não se enxergam.
- Uma rede `db-<app>` **interna** por aplicação que usa o Postgres.
- Um futuro SaaS teria Postgres próprio, nunca o compartilhado.

### 4.6 Identidade (Authentik)

- Versão fixada: `ghcr.io/goauthentik/server:2026.8.3` (com digest).
- Nasce **sem variáveis de bootstrap** (elas não aceitam `file://`; exigiriam o valor em
  variável de ambiente, o que viola a regra de segredos).
- O `post_deploy` roda `scripts/authentik-set-admin.sh`, que:
  1. espera o Authentik ficar pronto;
  2. aplica a senha do `akadmin` a partir de `/run/secrets/AKADMIN_PASSWORD`;
  3. faz o mesmo que a tela oficial de setup faz ao concluir: marca o setup como concluído,
     desativa os blueprints de configuração inicial e restringe o fluxo `initial-setup`.
  O script usa partes internas do Authentik (confirmadas no código da 2026.8):
  **revalidar ao atualizar a versão.**
- O Caddy bloqueia (403) `/setup*`, `/if/flow/initial-setup*` e
  `/api/v3/flows/executor/initial-setup*`, cobrindo a janela entre o container subir e o
  pós-deploy aplicar a senha.
- Plano (fase 4b): blueprints no repositório definindo grupos `admins` e `visitantes`,
  2FA obrigatório e o usuário pessoal `instance.admin_user` (o `akadmin` vira conta de emergência).
  **Configuração** (aplicações, grupos, políticas, fluxos) vai no repositório;
  **pessoas** (visitantes, convites, expiração) são estado, gerenciado pela interface.
- Plano (fase 4c em diante): cada ferramenta faz login via OIDC no Authentik;
  ferramentas sem OIDC ficam atrás de forward auth no Caddy.

### 4.7 Dados

- **Postgres** (`pgvector/pgvector:0.8.6-pg17`): compartilhado entre as ferramentas da plataforma.
  Cada aplicação tem usuário e banco próprios, criados por `scripts/pg-provision.sh` no
  `pre_deploy` da aplicação (idempotente; reaplica a senha a cada deploy).
- **Garage** (`dxflrs/garage:v2.4.1`): S3 de nó único, `replication_factor = 1`.
  Uso futuro: artefatos do MLflow, arquivos brutos de ingestão, possivelmente logs.
  Banco de dados nunca vai para o Garage (armazenamento de objetos não serve para isso).

### 4.8 Backup

- `ansible/backup.yml`: restic em `/var/backups/restic`, senha via SOPS em `/etc/restic/password`.
- Script `/usr/local/bin/prestes-backup`, timer diário às 03:30 (`Persistent=true`).
- Conteúdo: `pg_dumpall` do Postgres, snapshot de metadados + volumes do Garage,
  e os backups que o Komodo gera em `/etc/komodo/backups`.
- Retenção: 7 diários, 4 semanais, 6 mensais.
- Cópia externa (planejada): o rclone já está instalado; o repositório restic pode ser
  copiado para qualquer destino (notebook via SSH, Google Drive, R2…) sem mudar o backup.

### 4.9 DNS e domínios

- `prestes.cloud` e `*.prestes.cloud` (registro A wildcard) apontam para a VPS,
  gerenciados no painel da Hostinger (passo manual aceito; OpenTofu no futuro).

| Subdomínio | Destino | Estado |
|---|---|---|
| `prestes.cloud` | página estática (vitrine) | ✅ placeholder |
| `deploy.prestes.cloud` | Komodo (só `/listener/*` hoje) | ✅ parcial por design |
| `auth.prestes.cloud` | Authentik | ✅ |
| demais (`grafana.`, `mlflow.`, `windmill.`, `lightdash.`, `status.`…) | fases futuras | 📋 |

---

## 5. Estrutura do repositório

```
.
├── bootstrap.sh                  # init + checagem de commit/push + playbooks
├── secrets.enc.yaml              # todos os valores da instância, cifrados (scripts/init)
├── .instance                     # local, fora do git: nome da instância e caminho das chaves
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/all/main.yml   # lê .instance e secrets.enc.yaml
│   ├── requirements.yml          # community.general, ansible.posix, community.sops, community.docker
│   ├── check.yml                 # init --check, importado no início de cada playbook
│   ├── bootstrap.yml             # host
│   ├── komodo.yml                # Komodo Core + Periphery + Mongo
│   ├── backup.yml                # restic
│   └── secrets.spec.yaml
├── komodo/
│   ├── compose.yaml
│   ├── compose.env               # configuração não secreta
│   ├── secrets.spec.yaml         # Ansible gera /opt/komodo/.secrets/<CHAVE>
│   └── resources/
│       ├── sync.toml             # o próprio Resource Sync
│       ├── stacks.toml           # declaração dos stacks
│       └── procedures.toml       # deploy-on-push
├── stacks/
│   ├── caddy/     (compose.yaml, config/Caddyfile, site/)
│   ├── postgres/  (compose.yaml, secrets.spec.yaml)
│   ├── garage/    (compose.yaml, config/garage.toml, secrets.spec.yaml)
│   └── authentik/ (compose.yaml, secrets.spec.yaml)
├── scripts/
│   ├── init                      # chaves, .sops.yaml e secrets.enc.yaml (Python)
│   ├── decrypt-secrets.sh
│   ├── pg-provision.sh
│   ├── authentik-set-admin.sh
│   └── check-encrypted.sh        # falha se algum *.enc.* tiver valor fora de ENC[...]
├── .github/workflows/
│   └── secrets.yml               # roda o check-encrypted.sh em cada push
├── .sops.yaml                    # gerado pelo init: chave pessoal e a da VPS
├── .pre-commit-config.yaml       # gitleaks + hooks básicos + check-encrypted.sh
└── .gitignore                    # inclui .secrets/, .instance, *.agekey, .env
```

---

## 6. Como adicionar uma nova aplicação

1. `stacks/<app>/compose.yaml`
   - imagem com versão exata e digest (`imagem:versão@sha256:...`; o digest sai de
     `docker buildx imagetools inspect imagem:versão`);
   - rede `edge-<app>` (se tiver interface web), declarada com `name: edge-<app>`;
   - rede `db-<app>` como `external: true` (se usar Postgres);
   - segredos em `secrets:` apontando para `./.secrets/<CHAVE>`;
   - `mem_limit` definido (a VPS tem 8 GB);
   - sem `ports:` públicos.
2. `stacks/<app>/secrets.spec.yaml` declarando as chaves; rodar `scripts/init` (gera ou
   pergunta o que faltar) e commitar o `secrets.enc.yaml`.
3. Se usar Postgres: adicionar a rede `db-<app>` (interna) no `stacks/postgres/compose.yaml`
   e chamar `scripts/pg-provision.sh <app> <arquivo-da-senha>` no `pre_deploy`.
4. `komodo/resources/stacks.toml`: declarar o stack com `pre_deploy.command`
   (`sh /etc/komodo/stacks/<app>/scripts/decrypt-secrets.sh /etc/komodo/stacks/<app>/stacks/<app>`)
   e `post_deploy.command`, se necessário. Caminhos absolutos: `/etc/komodo/stacks/<app>/...`.
5. `komodo/resources/procedures.toml`: incluir `<app>` no estágio "Aplicações".
   (Mudou o procedure → rodar o sync manualmente uma vez.)
6. `stacks/caddy/config/Caddyfile`: rota do subdomínio; e a rede `edge-<app>` como externa
   no `stacks/caddy/compose.yaml`.
7. Login: OIDC no Authentik ou forward auth no Caddy.
8. Testar a reconstrução do zero.

---

## 7. Roadmap detalhado das fases futuras

- **4b — Authentik:** blueprints (grupos `admins`/`visitantes`, 2FA, usuário `instance.admin_user`, lido com `!File`).
  Verificar a sintaxe de blueprints na documentação da versão em uso antes de escrever.
- **4c — Komodo com SSO:** OIDC no Komodo, rota completa em `deploy.prestes.cloud`,
  grupo de visitantes com permissão de leitura (e leitura de logs) nos recursos.
- **5 — Observabilidade:** Grafana como painel central (acesso de visitante só leitura).
  Candidatos: Prometheus + Loki, ou VictoriaMetrics + VictoriaLogs (mais leve).
  Uptime Kuma para página de status pública. Coletores: node_exporter, cAdvisor, métricas
  do Caddy, Garage e Authentik. Grafana também consulta o Postgres diretamente
  (execuções do Windmill, runs do MLflow, resultados de testes do dbt).
- **6 — Plataforma de ML:**
  - MLflow (metadados no Postgres, artefatos no Garage; sem OIDC nativo → forward auth).
  - Windmill (orquestração; SSO via Authentik, verificar limites da edição comunitária).
  - dbt (transformação; docs publicadas como site estático).
  - Repositório `data-platform` com o projeto dbt e os scripts do Windmill, com CI próprio.
- **7 — Caso de uso de ponta a ponta:** ingestão → dbt → treino → MLflow → modelo servido,
  agendado e monitorado. Caso de uso ainda não escolhido (ex.: churn, fraude, tickets).
- **8 — Lightdash:** BI sobre o projeto dbt (métricas definidas no YAML do dbt).
- **9 — Agente:** repositório `agent-api` (FastAPI + LangChain `create_agent`), com
  ferramentas que consultam MLflow, Windmill, dbt e documentação (RAG com pgvector).
  Tracing no MLflow. Rate limit e teto de gasto do LLM (via API).
  Padrão GitOps de mercado: o CI do `agent-api` builda a imagem (tag = SHA do commit),
  publica no GHCR e abre PR neste repositório trocando a tag; o merge dispara o deploy.
- **10 — Vitrine e visitantes:** página inicial com diagrama e links; convites via Authentik.

Melhorias transversais planejadas:

- CI no GitHub Actions (validação de compose/TOML, rodar playbooks).
- OpenTofu para DNS (e possivelmente repositórios/webhooks do GitHub).
- Criação automática do Resource Sync via API do Komodo (hoje é o único passo manual do bootstrap).
- Cópia externa do backup.
- 2FA no Authentik com TOTP (Google Authenticator) ou passkeys.
- `docs/runbook.md` com os incidentes abaixo.

---

## 8. Passos manuais conhecidos (dívida de automação)

Estes passos são **manuais hoje, de forma consciente e temporária**. Não são falhas de
configuração, mas cada um é dívida em relação ao objetivo de template automatizado
(seção 11 diz o destino de cada um):

1. Guardar no gerenciador de senhas as chaves da instância (o `scripts/init` as cria).
2. Registros DNS no painel da Hostinger.
3. Ao (re)instalar a VPS: cadastrar a chave SSH da instância para root no painel da Hostinger
   (e, numa reinstalação, `ssh-keygen -R <host>`); depois rodar `./bootstrap.sh`.
4. Criar o Resource Sync `prestes-vps` na interface do Komodo, uma vez
   (repo `AlexPrestes/prestes-vps`, branch `main`, resource path `komodo/resources`).
5. Cadastrar o webhook no GitHub apontando para o procedure `deploy-on-push`.
6. Inicializar o layout do Garage uma vez (estado do cluster):
   `garage layout assign -z dc1 -c 40G <ID>` e `garage layout apply --version 1`.
7. Quando um push altera `procedures.toml`, rodar o sync manualmente antes do procedure.

---

## 9. Armadilhas já encontradas (e como foram resolvidas)

| Sintoma | Causa | Solução |
|---|---|---|
| Sync falha com `pathspec 'main' did not match` | clone em cache corrompido no Core | recriar o container do Core |
| Push só com mudança fora do compose não atualiza nada | `BatchDeployStackIfChanged` só compara o compose | usar `BatchDeployStack` |
| Mudança no Caddyfile não aplicada | arquivo montado individualmente mantém a versão antiga | montar a pasta `config/` e usar `caddy run --watch` |
| `procedure sync loop exited after max iterations` | procedure tentando alterar a si mesmo durante a execução | rodar o sync manualmente quando `procedures.toml` mudar |
| Pré-deploy falha sem mensagem | `[ cond ] && cmd` como última linha devolve código 1 | usar `if ...; then ...; fi` |
| Arquivo em `.secrets/` antigo persiste | script não limpava a pasta | `rm -rf` da pasta antes de gerar |
| Senha do `akadmin` virou o texto `file:///...` | variáveis de bootstrap não aceitam `file://` | sem bootstrap; senha aplicada no `post_deploy` |
| Raiz do Authentik redireciona para `/setup` | setup não marcado como concluído | o script faz o mesmo que a tela oficial de setup |
| `sudo -v` pede senha mesmo com NOPASSWD | `-v` exige que **todas** as regras sejam NOPASSWD | testar com `sudo whoami`; usuário não está no grupo `sudo` |
| Regra de sudoers ignorada | arquivos com `.` no nome são ignorados em `sudoers.d` | nome do arquivo sem ponto (`90-` + usuário com `_` no lugar de `.`) |

---

## 10. Operação do dia a dia

```bash
# Acesso ao Komodo (até a fase 4c)
ssh komodo              # com LocalForward 9120 no ~/.ssh/config
# → http://localhost:9120

# Editar segredos (ou apagar a chave e rodar scripts/init para gerar outra)
sops secrets.enc.yaml

# Aplicar mudanças no host
./bootstrap.sh                                  # tudo
cd ansible && ansible-playbook komodo.yml       # ou só um playbook

# Backup manual e verificação
sudo systemctl start prestes-backup.service
sudo restic -r /var/backups/restic --password-file /etc/restic/password snapshots
```

Contêineres seguem o padrão `<stack>-<serviço>-1` (ex.: `postgres-postgres-1`,
`authentik-worker-1`, `komodo-periphery-1`).

---

## 11. O repositório como template

### 11.1 Objetivo final

Uma pessoa que queira a própria instância deve precisar apenas de:

1. uma VPS Debian vazia com acesso SSH por chave;
2. um domínio com DNS apontando para ela (wildcard);
3. um fork deste repositório;
4. **um único arquivo de parâmetros** da instância (domínio, repositório, usuário admin,
   e-mail, host da VPS, chaves públicas age);
5. **gerar os próprios segredos** (um comando que cria as chaves age e todos os
   segredos com valores aleatórios) — feito: `scripts/init`;
6. **um único comando de bootstrap** (Ansible), a partir do qual todo o resto se constrói
   sozinho: host, Komodo, Resource Sync, webhook e todos os stacks, na ordem certa —
   em parte: `./bootstrap.sh` (faltam Resource Sync, webhook e layout do Garage).

### 11.2 Onde a instância `prestes.cloud` está hoje

A arquitetura já segue o modelo de template (tudo vem do repositório, segredos cifrados,
ordem de deploy declarada, reconstrução do zero testada no Authentik). O que ainda falta
são **valores fixos da instância** e **passos manuais**, listados abaixo como dívida.

**Valores fixos a parametrizar** (não replicar esse padrão em arquivos novos):

| Valor | Onde aparece hoje |
|---|---|
| `prestes.cloud` e subdomínios | `stacks/caddy/config/Caddyfile`, `komodo/compose.env` (`KOMODO_HOST`) |
| `AlexPrestes/prestes-vps` | `komodo/resources/sync.toml`, `komodo/resources/stacks.toml` |
| `prestes-vps` (nome do servidor/sync) | `komodo/compose.env`, `komodo/resources/*.toml`, `ansible/inventory` |
| host/IP da VPS | `ansible/inventory/hosts.yml` |
| fuso `America/Sao_Paulo` | `ansible/bootstrap.yml`, `komodo/compose.env` |
| capacidade do Garage (`40G`) | comando de layout (manual) |
| caminhos `/etc/komodo/stacks/<stack>/...` | `pre_deploy`/`post_deploy` em `stacks.toml` (derivados do nome do stack; ok) |

Direção pretendida: um arquivo de parâmetros (ex.: `instance.yaml`) lido pelo Ansible, que
**gera** os arquivos dependentes (Caddyfile, `compose.env`, TOMLs do Komodo, `.sops.yaml`)
a partir de templates, ou que os injeta como variáveis. A forma exata ainda não foi decidida.

Já parametrizados: usuário admin (`instance.admin_user`), chaves e segredos (seção 4.4);
o `.sops.yaml` é gerado pelo `scripts/init`.

**Destino de cada passo manual da seção 8:**

| Passo manual | Destino no template |
|---|---|
| Gerar chaves SSH/age | ✅ `scripts/init` (gera as que faltam ou usa as existentes) |
| DNS | Entrada do usuário do template; opcionalmente OpenTofu |
| Rodar os playbooks | ✅ `./bootstrap.sh` (depois, também via CI) |
| Criar o Resource Sync na interface | Ansible cria via API do Komodo |
| Cadastrar o webhook no GitHub | Ansible cria via API do GitHub (ou OpenTofu) |
| Layout do Garage | Automatizado (pós-deploy do stack ou API de administração do Garage) |
| Sync manual quando `procedures.toml` muda | Separar procedures num sync próprio, ou aceitar como exceção documentada |

### 11.3 Como tratar isso ao trabalhar no repositório

- Arquivos novos não devem introduzir novos valores fixos da instância.
- Parametrização é uma fase própria de trabalho: **não** trocar valores fixos existentes
  "de passagem" durante outra tarefa, porque isso quebra a instância em funcionamento.
- Qualquer automação nova deve funcionar numa VPS vazia, sem depender de estado criado à mão.
