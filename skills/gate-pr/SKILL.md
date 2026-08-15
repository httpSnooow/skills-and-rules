---
name: gate-pr
description: >-
  Pre-PR checklist that verifies a task is truly done before commit: scope
  respected, tests passing, no debug artifacts, no undeclared dependencies,
  no security regressions, impact verified. Use before considering any task
  complete or opening a pull request.
---

# Gate PR — Checklist de Conclusão

## Quando aplicar

Antes de considerar qualquer tarefa concluída, antes de abrir um PR, ou quando o usuário pede "revise o que foi feito". Esta skill executa **6 gates em sequência**. Todos devem passar.

## Gates

### Gate 1 — Escopo

- [ ] O que foi alterado corresponde **exatamente** ao que foi pedido?
- [ ] Há alterações fora do escopo? Se sim, estão sinalizadas separadamente em `## Observações fora do escopo` para o usuário decidir?
- [ ] Nenhuma refatoração não solicitada foi introduzida silenciosamente?

### Gate 2 — Testes

- [ ] Os novos comportamentos têm testes?
- [ ] Bugs corrigidos têm testes de regressão?
- [ ] Testes existentes que cobrem o código alterado ainda passam (verificar se há testes frágeis que precisam ser atualizados)?

### Gate 3 — Artefatos de desenvolvimento

- [ ] Não há `console.log`, `print`, `debugger`, `dump()` ou equivalentes esquecidos?
- [ ] Não há comentários `// TEMP`, `// FIXME`, `// TODO` sem rastreamento (sem número de issue ou ticket)?
- [ ] Não há código comentado que ficou "para depois"?

### Gate 4 — Dependências e configuração

- [ ] Dependências novas foram declaradas nos arquivos de manifesto (`package.json`, `requirements.txt`, etc.)?
- [ ] Env vars novas estão documentadas no `.env.example` ou equivalente?
- [ ] A mudança quebra alguma configuração de ambiente existente?

### Gate 5 — Segurança (verificação rápida)

- [ ] Secrets, tokens ou senhas aparecem em algum lugar do diff?
- [ ] Dados sensíveis aparecem em logs?
- [ ] Há montagem dinâmica de queries ou comandos com input de usuário?
- [ ] HTML dinâmico renderiza input sem sanitização?

### Gate 6 — Impacto

- [ ] A skill `verificar-impacto` foi executada (ou os passos foram seguidos manualmente)?
- [ ] Call sites de funções alteradas foram verificados?
- [ ] Feature flags afetadas foram verificadas nos dois estados (on/off)?

## Output esperado

Ao final da verificação, gerar um relatório no seguinte formato:

```
## Gate PR — Resultado

✅ Gate 1 — Escopo: [ok ou descrição do problema]
✅ Gate 2 — Testes: [ok ou descrição do problema]
⚠️ Gate 3 — Artefatos: [lista de itens encontrados, se houver]
✅ Gate 4 — Dependências: [ok ou descrição do problema]
✅ Gate 5 — Segurança: [ok ou descrição do problema]
✅ Gate 6 — Impacto: [ok ou descrição do problema]

Status: APROVADO / BLOQUEADO (motivo)
```

Usar `✅` para gates que passaram, `⚠️` para gates com observações não-bloqueantes, e `❌` para gates que bloqueiam o PR.

## O que evitar

- Marcar todos os gates como "ok" sem verificar de fato — cada gate exige leitura do diff.
- Ignorar Gate 5 (segurança) por ser "verificação rápida" — as vulnerabilidades mais comuns são encontradas aqui.
- Rodar este checklist apenas no final — idealmente, cada gate é verificado incrementalmente durante o desenvolvimento.
