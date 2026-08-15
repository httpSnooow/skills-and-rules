# Exemplo golden — projeto fictício Next.js + API

Few-shot do que a skill deve **gerar** (preenchido). Não copiar nomes SPI. Projeto exemplo: `acme-portal` (Next.js App Router + pasta `api/` Nest-like).

## Camadas detectadas (análise)

| Pasta | Concern | Persona |
|---|---|---|
| `apps/web/app/**`, `components/**` | UI | `[Agente de Frontend/UI]` |
| `apps/web/lib/**`, `apps/web/services/**` | HTTP/data client | `[Agente de Frontend/Data]` |
| `apps/api/src/**/controllers/**` | HTTP borda | `[Agente de API/Borda]` |
| `apps/api/src/**/services/**` | Dominio | `[Agente de Dominio]` |
| `apps/api/src/**/repositories/**` | Persistencia | `[Agente de Infra/Dados]` |

Fluxo: `UI → lib/services → API controller → service → repository`.

## Trechos preenchidos (referencia)

### `.ai/context.md` (resumo)

~~~~markdown
# acme-portal — Contexto Global de IA (Local)

## Visão do produto
Portal interno Acme: autenticacao, dashboard e CRUD de clientes.

## Stack
- Frontend: Next.js 15, React, TypeScript, Tailwind
- API: NestJS, Prisma, PostgreSQL

## Arquitetura / comunicação entre camadas
UI → lib/services → API controller → service → repository → Prisma/DB

## Pastas canônicas
`apps/web/app`, `apps/web/components`, `apps/web/lib`, `apps/web/services`,
`apps/api/src/.../controllers|services|repositories`
~~~~

### `.ai/agents.md` (uma persona exemplo)

~~~~markdown
## [Agente de Dominio]

**Camadas:** `apps/api/src/**/services/**`
**Foco:** casos de uso, validacoes, orquestracao de repositories.

**Pode**
- Implementar services e regras de negocio
- Orquestrar repositories

**Nao pode**
- Definir rotas HTTP
- Conhecer componentes React
- SQL cru se ja existir repository/Prisma padrao

**Referencias:** `.ai/layers/services.md`
~~~~

### `.ai/layers/services.md` (exemplo)

~~~~markdown
# Camada: services (API)

**Pacotes/pastas:** `apps/api/src/**/services/**/*.ts`
**Persona:** [Agente de Dominio]

## Responsabilidade
Casos de uso e invariantes.

## Obrigatorio
- Validar regras antes de persistir
- Usar repositories/Prisma do modulo

## Proibido
- Decorators de controller / status HTTP
- JSX / imports de `apps/web`

## Exemplo

    ERRADO: @Get() dentro do service
    CERTO: createCustomer(dto) → repository.create

## Oracle
Negocio testavel sem subir HTTP server.
~~~~

### `.cursor/rules/00-architecture.mdc` (exemplo)

~~~~markdown
---
description: Arquitetura e boot de contexto IA local — acme-portal
alwaysApply: true
---

# acme-portal — Arquitetura

UI → lib/services → API controller → service → repository → DB.

- Zero alucinacao de endpoint/campo.
- Nunca ler `.env` / secrets.
- Contexto: `.ai/context.md`, `.ai/agents.md`, `.ai/layers/`, `.ai/features/`.

## Boot
1. Uma persona.
2. Features `Status: active` em `.ai/features/` (exceto `_template` e `_done/`).
3. Layer do arquivo aberto.
4. Sem inventar contrato.
~~~~

### `.cursor/rules/frontend-data.mdc` (exemplo de glob)

~~~~markdown
---
description: Limites de data client (lib/services web)
globs: "apps/web/lib/**/*.{ts,tsx},apps/web/services/**/*.{ts,tsx}"
alwaysApply: false
---

# Frontend Data

HTTP tipado apenas. Sem JSX. Sem inventar endpoints.

Detalhes: `.ai/layers/frontend-data.md`
~~~~

## Arvore minima esperada apos a skill

~~~~
.ai/
  context.md
  agents.md
  README.md
  layers/   (controllers, services, repositories, frontend-ui, frontend-data, ...)
  features/_template.md
  features/README.md
  features/_done/README.md
  playbooks/feature-cycle.md
  scripts/verify-local.ps1
  scripts/verify-local.sh
.cursor/
  rules/00-architecture.mdc
  rules/*.mdc
  hooks.json
  hooks/inject-active-features.ps1
  hooks/inject-active-features.sh
.cursorignore
~~~~

## Prompt diario (apos montagem)

~~~~
Atue como [Agente de Dominio].
@.ai/features/criar-cliente.md
@.ai/layers/services.md
~~~~

---

## Exemplo 2 — Django MTV (curto)

Projeto ficticio `acme-crm` (Django + DRF).

### Mapa pasta → persona

| Pasta | Concern | Persona |
|---|---|---|
| `apps/*/views.py`, `apps/*/viewsets.py` | Borda HTTP | `[Agente de API/Borda]` |
| `apps/*/services.py` | Dominio | `[Agente de Dominio]` |
| `apps/*/models.py`, `apps/*/selectors.py` | Dados | `[Agente de Infra/Dados]` |
| `templates/`, `static/` | UI server-side | `[Agente de Frontend/UI]` |

Fluxo: `view/viewset → service → model/selector/ORM`.

### Layer filled (referencia)

~~~~markdown
# Camada: services (Django)

**Pacotes/pastas:** `apps/**/services.py`
**Persona:** [Agente de Dominio]

## Responsabilidade
Casos de uso e invariantes de negocio.

## Obrigatorio
- Validar regras antes de gravar
- Usar models/selectors do app

## Proibido
- Retornar HttpResponse / Response DRF
- Queries complexas sem selector quando o app ja usa esse padrao

## Exemplo

    ERRADO: JsonResponse dentro de services.py
    CERTO: create_order(dto) → Order.objects.create(...)

## Oracle
Service testavel sem request HTTP.
~~~~

### Rule glob (referencia)

~~~~markdown
---
description: Limites services Django
globs: "**/services.py,apps/**/services.py"
alwaysApply: false
---

# services
Dominio apenas. Sem HttpResponse.

Detalhes: `.ai/layers/services.md`
~~~~
