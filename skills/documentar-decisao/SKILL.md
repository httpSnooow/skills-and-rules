---
name: documentar-decisao
description: >-
  Generates a lightweight ADR (Architectural Decision Record) when a non-obvious
  abstraction, pattern change, or architectural choice is introduced. Use when
  adding a design pattern, changing a shared contract, or when the reason for
  a structural choice won't be obvious from the code alone.
---

# Documentar Decisão — ADR (Architectural Decision Record)

## Quando aplicar

- Ao introduzir uma abstração não óbvia (ex: Factory, Strategy, middleware customizado)
- Ao mudar um padrão compartilhado (ex: trocar REST por GraphQL em um módulo)
- Ao adicionar uma dependência nova com impacto arquitetural
- Quando o usuário pede "documente por que foi feito assim"

**Não aplicar** para decisões triviais (escolha de nome de variável, formatação, import order).

## Relação com `explicar-decisao-tecnica`

A skill `explicar-decisao-tecnica` é **pedagógica** — explica na resposta do chat, inline. Esta skill é **persistível** — gera um arquivo ADR versionável que vai para o repositório do produto.

## Formato do ADR gerado

```markdown
# ADR-NNN: [Título curto — o que foi decidido]

**Data:** YYYY-MM-DD
**Status:** Proposta | Aceita | Substituída por ADR-NNN
**Contexto:** [arquivos/módulos afetados]

## Contexto e Problema

[1-2 parágrafos: qual dor ou limitação motivou a decisão. Ser específico sobre
o código, não genérico.]

## Opções Consideradas

### Opção A — [nome] (escolhida)
[Descrição em 2-3 linhas]
- ✅ [vantagem 1]
- ✅ [vantagem 2]
- ⚠️ [trade-off 1]

### Opção B — [nome] (rejeitada)
[Descrição em 2-3 linhas]
- Motivo da rejeição: [1 frase]

### Opção C — Não fazer nada
- Motivo da rejeição: [1 frase]

## Decisão

[A Opção A foi escolhida porque ...]

## Consequências

**Positivas:**
- [o que melhora]

**Negativas / dívidas aceitas:**
- [o que piora ou o que precisará ser revisado no futuro]

## Quando revisar

[Critério específico: ex. "quando o número de consumidores deste serviço
ultrapassar 5" ou "quando migrarmos para a versão X do framework"]
```

## Onde salvar

- Por padrão, em `docs/adr/ADR-NNN-titulo-kebab-case.md`
- Se o projeto não tiver pasta `docs/adr/`, criar e mencionar ao usuário
- ADRs são versionáveis — vão para o repositório do produto (diferente dos arquivos do `.ai/`, que são governança local)

## Numeração

- Verificar o maior número existente em `docs/adr/` e incrementar
- Se não houver ADRs, começar com `ADR-001`
- Usar 3 dígitos com zero-padding (`001`, `002`, ..., `999`)

## Checklist rápido

- [ ] O ADR descreve o problema concreto que motivou a decisão (não só a solução)?
- [ ] Pelo menos 2 opções foram consideradas (incluindo "não fazer nada")?
- [ ] Os trade-offs da opção escolhida estão explícitos?
- [ ] Há um critério de revisão definido ("quando revisitar esta decisão")?
- [ ] O arquivo foi salvo em `docs/adr/` com numeração sequencial?

## O que evitar

- Criar ADR para decisões triviais ou temporárias — o custo de manutenção não compensa
- Escrever ADRs genéricos ("decidimos usar boas práticas") — ser específico sobre o código e o contexto
- Deixar o status como "Proposta" indefinidamente — se foi implementado, marcar como "Aceita"
